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
#include <cstdio>  // 用于printf

namespace spleeter {

// 构造函数
AudioProcessor::AudioProcessor() {
}

// 析构函数
AudioProcessor::~AudioProcessor() {
}

// 设置delegate
void AudioProcessor::setDelegate(std::weak_ptr<IAudioProcessorDelegate> delegate) {
    delegate_ = delegate;
}

// 提取 Waveform 子段
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

// 复制子段到目标 Waveform（直接赋值）
void AudioProcessor::CopySubsegment(const Waveform& src, size_t src_start_frame, size_t frames,
                                   Waveform& dst, size_t dst_start_frame) {
    for (size_t f = 0; f < frames; ++f) {
        for (std::int32_t ch = 0; ch < src.nb_channels; ++ch) {
            size_t src_idx = (src_start_frame + f) * src.nb_channels + ch;
            size_t dst_idx = (dst_start_frame + f) * dst.nb_channels + ch;
            if (src_idx < src.data.size() && dst_idx < dst.data.size()) {
                dst.data[dst_idx] = src.data[src_idx]; // 直接赋值
            }
        }
    }
}

// 主处理函数：使用滑动窗口处理音频，返回指定数量的音轨
std::vector<Waveform> AudioProcessor::ProcessAudio(const Waveform& inputWaveform, 
                                                   std::shared_ptr<TFLiteInferenceEngine> interface_engine, 
                                                   size_t num_tracks, 
                                                   float window_seconds) {
    const int sample_rate = 44100;
    
    // 通知开始处理
    reportStart();
    
    // 根据传入的窗口大小计算其他参数
    const float step_seconds = window_seconds / 2.0f;           // 步长：窗口大小的一半
    const float first_take_seconds = window_seconds * 3.0f / 4.0f; // 第一个窗口取前3/4
    const float regular_take_seconds = step_seconds;             // 后续窗口都取中间step_seconds
    const float regular_offset_seconds = step_seconds / 2.0f;   // 中间段的偏移：step_seconds的一半
    
    const size_t window_frames = static_cast<size_t>(window_seconds * sample_rate);
    const size_t step_frames = static_cast<size_t>(step_seconds * sample_rate);
    const size_t first_take_frames = static_cast<size_t>(first_take_seconds * sample_rate);
    const size_t regular_take_frames = static_cast<size_t>(regular_take_seconds * sample_rate);
    const size_t regular_offset_frames = static_cast<size_t>(regular_offset_seconds * sample_rate);
    
    const size_t total_frames = inputWaveform.nb_frames;
    const int channels = inputWaveform.nb_channels;

    // 初始化结果容器（使用传入的音轨数量）
    std::vector<Waveform> track_results(num_tracks);
    for (size_t i = 0; i < num_tracks; ++i) {
        track_results[i].nb_frames = static_cast<std::int32_t>(total_frames);
        track_results[i].nb_channels = channels;
        track_results[i].data.resize(total_frames * channels, 0.0f);
    }

    size_t result_pos = 0;  // 当前写入结果的位置
    size_t window_start = 0; // 当前处理窗口的起始位置
    bool is_first_window = true;
    float last_reported_progress = 0.0f; // 上次报告的进度
    const float progress_report_threshold = 0.05f; // 进度报告阈值（5%）

    while (result_pos < total_frames) {
        // 计算当前进度
        float current_progress = static_cast<float>(result_pos) / static_cast<float>(total_frames);
        
        // 当进度变化超过阈值时才报告，避免过于频繁的回调
        if (current_progress - last_reported_progress >= progress_report_threshold) {
            reportProgress(current_progress);
            last_reported_progress = current_progress;
        }
        
        // 确定当前窗口的结束位置
        size_t window_end = std::min(window_start + window_frames, total_frames);
        size_t current_window_frames = window_end - window_start;
        
        // 如果窗口太小就直接退出
        if (current_window_frames == 0) break;
        
        // 提取当前窗口的音频
        Waveform window_segment = ExtractSubsegment(inputWaveform, window_start, current_window_frames);
        
        // 处理当前窗口
        interface_engine->Init();
        interface_engine->Execute(window_segment);
        auto results = interface_engine->GetResults();
        interface_engine->Shutdown();
        
        // 确保返回的结果数量与期望的一致
        if (results.size() != num_tracks) {
            std::string error_msg = "返回的音轨数量不一致，期望 " + std::to_string(num_tracks) + "，实际 " + std::to_string(results.size());
            reportError(error_msg);
            return track_results; // 返回已处理的部分
        }
        
        // 确定从处理结果中取哪一段
        size_t extract_start, extract_frames;
        if (is_first_window) {
            // 第一个窗口：取前3/4
            extract_start = 0;
            extract_frames = std::min(first_take_frames, static_cast<size_t>(results[0].nb_frames));
            extract_frames = std::min(extract_frames, total_frames - result_pos);
            is_first_window = false;
        } else {
            // 后续窗口：取中间部分
            extract_start = regular_offset_frames;
            extract_frames = std::min(regular_take_frames, static_cast<size_t>(results[0].nb_frames) - extract_start);
            extract_frames = std::min(extract_frames, total_frames - result_pos);
        }
        
        // 边界检查
        if (extract_start >= static_cast<size_t>(results[0].nb_frames) || extract_frames == 0) {
            break;
        }
        
        // 将提取的片段复制到所有音轨的最终结果
        for (size_t track_idx = 0; track_idx < num_tracks; ++track_idx) {
            CopySubsegment(results[track_idx], extract_start, extract_frames, track_results[track_idx], result_pos);
        }
        
        // 更新位置
        result_pos += extract_frames;
        window_start += step_frames;
        
        // 如果已经处理完所有音频，退出循环
        if (window_start >= total_frames) {
            break;
        }
    }
    
    // 处理可能的剩余部分（最后一个不完整窗口）
    if (result_pos < total_frames) {
        size_t remaining_frames = total_frames - result_pos;
        if (window_start < total_frames) {
            // 处理最后一个窗口
            size_t final_window_end = total_frames;
            size_t final_window_frames = final_window_end - window_start;
            
            if (final_window_frames > 0) {
                Waveform final_segment = ExtractSubsegment(inputWaveform, window_start, final_window_frames);
                
                interface_engine->Init();
                interface_engine->Execute(final_segment);
                auto results = interface_engine->GetResults();
                interface_engine->Shutdown();
                
                // 取这个窗口的前面部分来填充剩余空间
                size_t copy_frames = std::min(remaining_frames, static_cast<size_t>(results[0].nb_frames));
                for (size_t track_idx = 0; track_idx < num_tracks; ++track_idx) {
                    CopySubsegment(results[track_idx], 0, copy_frames, track_results[track_idx], result_pos);
                }
            }
        }
    }

    // 确保最终进度为100%
    reportProgress(1.0f);
    
    // 通知处理完成
    reportFinish();
    
    return track_results;
}

// 私有方法实现
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

void AudioProcessor::reportFinish() {
    if (auto delegate = delegate_.lock()) {
        delegate->onProcessingFinish();
    }
}

void AudioProcessor::reportError(const std::string& error) {
    if (auto delegate = delegate_.lock()) {
        delegate->onProcessingError(error);
    }
}

} // namespace spleeter
