//
//  AudioProcessor.cpp
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/19.
//

#include "AudioProcessor.h"
#include "TFLiteInferenceEngine.h"
#include <algorithm>
#include <cstdint>
#include <cstdio>

namespace spleeter {

AudioProcessor::AudioProcessor() {
}

AudioProcessor::~AudioProcessor() {
}

void AudioProcessor::setDelegate(std::weak_ptr<IAudioProcessorDelegate> delegate) {
    delegate_ = delegate;
}

Waveform AudioProcessor::ExtractSubsegment(const Waveform& src, size_t start_frame, size_t frames) {
    Waveform seg;
    seg.nb_frames = static_cast<std::int32_t>(frames);
    seg.nb_channels = src.nb_channels;
    seg.data.resize(frames * src.nb_channels, 0.0f);
    if (start_frame < src.nb_frames) {
        size_t copy_frames = std::min(frames, static_cast<size_t>(src.nb_frames) - start_frame);
        std::copy(src.data.begin() + start_frame * src.nb_channels,
                  src.data.begin() + (start_frame + copy_frames) * src.nb_channels,
                  seg.data.begin());
    }
    return seg;
}

void AudioProcessor::CopySubsegment(const Waveform& src, size_t src_start_frame, size_t frames,
                                   Waveform& dst, size_t dst_start_frame) {
    for (size_t f = 0; f < frames; ++f) {
        for (std::int32_t ch = 0; ch < src.nb_channels; ++ch) {
            size_t src_idx = (src_start_frame + f) * src.nb_channels + ch;
            size_t dst_idx = (dst_start_frame + f) * dst.nb_channels + ch;
            if (src_idx < src.data.size() && dst_idx < dst.data.size()) {
                dst.data[dst_idx] = src.data[src_idx];
            }
        }
    }
}

std::vector<Waveform> AudioProcessor::ProcessAudio(const Waveform& inputWaveform, 
                                                   std::shared_ptr<TFLiteInferenceEngine> interface_engine, 
                                                   size_t num_tracks, 
                                                   float window_seconds) {
    const int sample_rate = 44100;

    reportStart();

    const float step_seconds = window_seconds / 2.0f;
    const float first_take_seconds = window_seconds * 3.0f / 4.0f;
    const float regular_take_seconds = step_seconds;
    const float regular_offset_seconds = step_seconds / 2.0f;
    
    const size_t window_frames = static_cast<size_t>(window_seconds * sample_rate);
    const size_t step_frames = static_cast<size_t>(step_seconds * sample_rate);
    const size_t first_take_frames = static_cast<size_t>(first_take_seconds * sample_rate);
    const size_t regular_take_frames = static_cast<size_t>(regular_take_seconds * sample_rate);
    const size_t regular_offset_frames = static_cast<size_t>(regular_offset_seconds * sample_rate);
    
    const size_t total_frames = inputWaveform.nb_frames;
    const int channels = inputWaveform.nb_channels;

    std::vector<Waveform> track_results(num_tracks);
    for (size_t i = 0; i < num_tracks; ++i) {
        track_results[i].nb_frames = static_cast<std::int32_t>(total_frames);
        track_results[i].nb_channels = channels;
        track_results[i].data.resize(total_frames * channels, 0.0f);
    }

    size_t result_pos = 0;
    size_t window_start = 0;
    bool is_first_window = true;
    float last_reported_progress = 0.0f;
    const float progress_report_threshold = 0.05f;

    while (result_pos < total_frames) {
        float current_progress = static_cast<float>(result_pos) / static_cast<float>(total_frames);

        if (current_progress - last_reported_progress >= progress_report_threshold) {
            reportProgress(current_progress);
            last_reported_progress = current_progress;
        }

        size_t window_end = std::min(window_start + window_frames, total_frames);
        size_t current_window_frames = window_end - window_start;

        if (current_window_frames == 0) break;

        Waveform window_segment = ExtractSubsegment(inputWaveform, window_start, current_window_frames);

        interface_engine->Init();
        interface_engine->Execute(window_segment);
        auto results = interface_engine->GetResults();
        interface_engine->Shutdown();

        if (results.size() != num_tracks) {
            std::string error_msg = "The number of returned tracks is inconsistent. Expected "
                                    + std::to_string(num_tracks)
                                    + ", but got "
                                    + std::to_string(results.size());
            return track_results;
        }

        size_t extract_start, extract_frames;
        if (is_first_window) {
            extract_start = 0;
            extract_frames = std::min(first_take_frames, static_cast<size_t>(results[0].nb_frames));
            extract_frames = std::min(extract_frames, total_frames - result_pos);
            is_first_window = false;
        } else {
            extract_start = regular_offset_frames;
            extract_frames = std::min(regular_take_frames, static_cast<size_t>(results[0].nb_frames) - extract_start);
            extract_frames = std::min(extract_frames, total_frames - result_pos);
        }

        if (extract_start >= static_cast<size_t>(results[0].nb_frames) || extract_frames == 0) {
            break;
        }

        for (size_t track_idx = 0; track_idx < num_tracks; ++track_idx) {
            CopySubsegment(results[track_idx], extract_start, extract_frames, track_results[track_idx], result_pos);
        }

        result_pos += extract_frames;
        window_start += step_frames;

        if (window_start >= total_frames) {
            break;
        }
    }

    if (result_pos < total_frames) {
        size_t remaining_frames = total_frames - result_pos;
        if (window_start < total_frames) {
            size_t final_window_end = total_frames;
            size_t final_window_frames = final_window_end - window_start;
            
            if (final_window_frames > 0) {
                Waveform final_segment = ExtractSubsegment(inputWaveform, window_start, final_window_frames);
                
                interface_engine->Init();
                interface_engine->Execute(final_segment);
                auto results = interface_engine->GetResults();
                interface_engine->Shutdown();

                size_t copy_frames = std::min(remaining_frames, static_cast<size_t>(results[0].nb_frames));
                for (size_t track_idx = 0; track_idx < num_tracks; ++track_idx) {
                    CopySubsegment(results[track_idx], 0, copy_frames, track_results[track_idx], result_pos);
                }
            }
        }
    }

    reportProgress(1.0f);
    
    return track_results;
}

void AudioProcessor::reportProgress(float progress) {
    if (auto delegate = delegate_.lock()) {
        delegate->onProgressUpdate(progress);
    }
}

void AudioProcessor::reportStart() {
    if (auto delegate = delegate_.lock()) {
        delegate->onProcessingStart();
    }
}
} // namespace spleeter
