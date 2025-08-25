//
//  SpleeterIOS.mm
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/25.
//
#import <sys/utsname.h>

#import "TFLiteInferenceEngine.h"
#import "FfmpegAudioAdapter.h"
#import "AudioProcessor.h"
#import "AudioProcessorDelegateImp.h"

#import "SpleeterIOS.h"

@interface SpleeterIOS () <AudioProcessorViewDelegate> {
    std::shared_ptr<spleeter::TFLiteInferenceEngine> _interfaceEngine;
    std::shared_ptr<spleeter::FFmpegAudioAdapter> _audioAdapter;
    std::shared_ptr<spleeter::AudioProcessor> _audioProcessor;
    std::shared_ptr<spleeter::AudioProcessorDelegateImp> _delegateImp;
    SpleeterModel _model;
}

@property (nonatomic, strong) void(^onStartHandler)();
@property (nonatomic, strong) void(^onProgressHandler)(float);
@property (nonatomic, strong) void(^onCompletionHandler)(BOOL, NSError*);
@property (nonatomic, strong) NSLock *lock;

@end

@implementation SpleeterIOS

+ (SpleeterIOS *)sharedInstance {
    static SpleeterIOS *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _audioAdapter = std::make_shared<spleeter::FFmpegAudioAdapter>();
        _delegateImp = std::make_shared<spleeter::AudioProcessorDelegateImp>(self);
        _audioProcessor = std::make_shared<spleeter::AudioProcessor>();
        _audioProcessor->setDelegate(_delegateImp);
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)processFileAt:(NSString *)path usingModel:(SpleeterModel)model saveAt:(NSString *)folder onStart:(void (^)())startHandler onProgress:(void (^)(float))progressHandler onCompletion:(void (^)(BOOL, NSError * _Nullable))completionHandler {
    _model = model;
    _onStartHandler = startHandler;
    _onProgressHandler = progressHandler;
    _onCompletionHandler = completionHandler;
    spleeter::InferenceEngineParameters _2StemsInferenceEngineParams{
        [[[NSBundle mainBundle] pathForResource:@"2stems" ofType:@"tflite"] UTF8String],
        "waveform",
        {"strided_slice_23", "strided_slice_13"},
        "spleeter:2stems"};

    spleeter::InferenceEngineParameters _5StemsInferenceEngineParams{
        [[[NSBundle mainBundle] pathForResource:@"5stems" ofType:@"tflite"] UTF8String],
        "waveform",
        {"strided_slice_18", "strided_slice_38", "strided_slice_48", "strided_slice_28", "strided_slice_58"},
        "spleeter:5stems"};
    if (model == SpleeterModel2Stems) {
        _interfaceEngine = std::make_shared<spleeter::TFLiteInferenceEngine>(_2StemsInferenceEngineParams);
    } else {
        _interfaceEngine = std::make_shared<spleeter::TFLiteInferenceEngine>(_5StemsInferenceEngineParams);
    }
    [self doProcesFileAt:path saveAt:folder];
}

- (void)doProcesFileAt:(NSString *)path saveAt:(NSString *)folder {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        auto waveform_names_2stems = std::vector<std::string>{"vocal", "accompaniment"};
        auto waveform_names_5stems = std::vector<std::string>{"vocal", "drums", "bass", "piano", "accompaniment"};
        const char* filePathCStr = [path UTF8String];
        const auto fullWaveform = self->_audioAdapter->Load(filePathCStr, 44100);

        size_t num_tracks = self->_model == SpleeterModel2Stems ? 2 : 5;

        std::vector<std::string> track_names;

        if (num_tracks == 2) {
            track_names = waveform_names_2stems;
        } else if (num_tracks == 5) {
            track_names = waveform_names_5stems;
        }

        float window_seconds = [self getOptimalWindowSeconds:num_tracks];

#if DEBUG
        NSLog(@"using %zustems，window size: %.1fs", num_tracks, window_seconds);
#endif
        const auto waveforms = self->_audioProcessor->ProcessAudio(fullWaveform, self->_interfaceEngine, num_tracks, window_seconds);
#if DEBUG
        NSLog(@"finished，got %zu tracks", waveforms.size());
#endif

        for (size_t i = 0; i < waveforms.size() && i < track_names.size(); ++i) {
            NSString *trackName = [NSString stringWithUTF8String:track_names[i].c_str()];
            NSString *trackPath = [folder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3", trackName]];

            self->_audioAdapter->Save(trackPath.UTF8String, waveforms[i], 44100, 128000);

#if DEBUG
            NSLog(@"saved track：%@ -> %@", trackName, trackPath);
#endif
        }
    });
}

- (float)getOptimalWindowSeconds:(size_t)numTracks {
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    unsigned long long totalMemory = processInfo.physicalMemory;
    BOOL isIOSAppRunOnMac = [processInfo isiOSAppOnMac];

    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    float baseWindowSeconds = 12.0f;

    if (numTracks == 2) {
        baseWindowSeconds = 12.0f;
    } else if (numTracks == 5) {
        baseWindowSeconds = 8.0f;
    } else {
        baseWindowSeconds = std::max(6.0f, 12.0f - (numTracks - 2) * 1.0f);
    }

    float memoryGB = totalMemory / (1024.0f * 1024.0f * 1024.0f);
    float memoryFactor = 1.0f;

    if (memoryGB >= 16.0f) {
        memoryFactor = 3.0f;
    } else if (memoryGB >= 8.0f) {
        memoryFactor = 2.0f;
    } else if (memoryGB >= 6.0f) {
        memoryFactor = 1.2f;
    }  else if (memoryGB >= 4.0f) {
        memoryFactor = 1.0f;
    } else if (memoryGB >= 2.0f) {
        memoryFactor = 0.75f;
    } else {
        memoryFactor = 0.5f;
    }

    if ([deviceModel containsString:@"iPhone16"] ||
        [deviceModel containsString:@"iPhone15"] ||
        [deviceModel containsString:@"iPhone14"] ||
        ([deviceModel containsString:@"iPad"] && !isIOSAppRunOnMac)) {
        memoryFactor *= 1.2f;
    }

    float finalWindowSeconds = baseWindowSeconds * memoryFactor;

    finalWindowSeconds = std::max(4.0f, std::min(60.0f, finalWindowSeconds));

    NSLog(@"total memory: %.1fGB, device model: %@, base window: %.1fs, memory factor: %.2f, final window: %.1fs",
          memoryGB, deviceModel, baseWindowSeconds, memoryFactor, finalWindowSeconds);

    return finalWindowSeconds;
}

#pragma mark - AudioProcessorViewDelegate
- (void)audioProcessorDidUpdateProgress:(float)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.onProgressHandler) {
            self.onProgressHandler(progress);
        }
    });
}

- (void)audioProcessorDidStart {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.onStartHandler) {
            self.onStartHandler();
        }
    });
}

- (void)audioProcessorDidFinish {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.onCompletionHandler) {
            self.onCompletionHandler(YES, nil);
        }
    });
}

- (void)audioProcessorDidFailWithError:(NSString *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.onCompletionHandler) {
            self.onCompletionHandler(NO, [NSError errorWithDomain:@"com.stemify.client" code:-1 userInfo:nil]);
        }
    });
}

@end
