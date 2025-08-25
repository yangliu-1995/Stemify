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

// C++抽象类 - 进度监听接口
class IAudioProcessorDelegate {
public:
    virtual ~IAudioProcessorDelegate() = default;
    
    // 进度更新回调：progress 范围 0.0 - 1.0
    virtual void onProgressUpdate(float progress) = 0;
    
    // 开始处理回调
    virtual void onProcessingStart() = 0;
    
    // 完成处理回调
    virtual void onProcessingFinish() = 0;
    
    // 错误回调
    virtual void onProcessingError(const std::string& error) = 0;
};

class AudioProcessor {
public:
    // 构造函数
    AudioProcessor();

    // 析构函数
    ~AudioProcessor();

    // 设置delegate (weak reference)
    void setDelegate(std::weak_ptr<IAudioProcessorDelegate> delegate);

    // 提取 Waveform 子段 (改为实例方法)
    Waveform ExtractSubsegment(const Waveform& src, size_t start_frame, size_t frames);

    // 复制子段到目标 Waveform（直接赋值）(改为实例方法)
    void CopySubsegment(const Waveform& src, size_t src_start_frame, size_t frames,
                        Waveform& dst, size_t dst_start_frame);

    // 主处理函数：使用滑动窗口处理音频，返回指定数量的音轨 (改为实例方法)
    std::vector<Waveform> ProcessAudio(const Waveform& inputWaveform,
                                       std::shared_ptr<TFLiteInferenceEngine> interface_engine,
                                       size_t num_tracks,
                                       float window_seconds);

private:
    std::weak_ptr<IAudioProcessorDelegate> delegate_;

    // 报告进度的私有方法
    void reportProgress(float progress);
    void reportStart();
    void reportFinish();
    void reportError(const std::string& error);

};
} // namespace spleeter
