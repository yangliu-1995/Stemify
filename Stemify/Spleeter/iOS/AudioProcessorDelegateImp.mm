//
//  AudioProcessorDelegateImp.mm
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/19.
//

#import "AudioProcessorDelegateImp.h"

namespace spleeter {
AudioProcessorDelegateImp::AudioProcessorDelegateImp(__weak id<AudioProcessorViewDelegate> viewDelegate)
    : viewDelegate_(viewDelegate) {
}

AudioProcessorDelegateImp::~AudioProcessorDelegateImp() {
    viewDelegate_ = nil;
}

void AudioProcessorDelegateImp::onProgressUpdate(float progress) {
    if (viewDelegate_ && [viewDelegate_ respondsToSelector:@selector(audioProcessorDidUpdateProgress:)]) {
        [viewDelegate_ audioProcessorDidUpdateProgress:progress];
    }
}

void AudioProcessorDelegateImp::onProcessingStart() {
    if (viewDelegate_ && [viewDelegate_ respondsToSelector:@selector(audioProcessorDidStart)]) {
        [viewDelegate_ audioProcessorDidStart];
    }
}
} // namespace spleeter
