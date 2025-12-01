//
//  AudioProcessor.h
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/19.
//
#pragma once

#include "waveform.h"
#include <vector>
#include <memory>

namespace spleeter {

class TFLiteInferenceEngine;

class IAudioProcessorDelegate {
public:
    virtual ~IAudioProcessorDelegate() = default;

    virtual void onProgressUpdate(float progress) = 0;

    virtual void onProcessingStart() = 0;
};

class AudioProcessor {
public:
    AudioProcessor();

    ~AudioProcessor();

    void setDelegate(std::weak_ptr<IAudioProcessorDelegate> delegate);

    Waveform ExtractSubsegment(const Waveform& src, size_t start_frame, size_t frames);

    void CopySubsegment(const Waveform& src, size_t src_start_frame, size_t frames,
                        Waveform& dst, size_t dst_start_frame);

    std::vector<Waveform> ProcessAudio(const Waveform& inputWaveform,
                                       std::shared_ptr<TFLiteInferenceEngine> interface_engine,
                                       size_t num_tracks,
                                       float window_seconds);

private:
    std::weak_ptr<IAudioProcessorDelegate> delegate_;

    void reportProgress(float progress);
    void reportStart();
};
} // namespace spleeter
