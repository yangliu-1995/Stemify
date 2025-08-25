//
//  AudioProcessorDelegateImp.h
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/19.
//
#pragma once

#include "AudioProcessor.h"
#include "AudioProcessorDelegate.h"

#import <Foundation/Foundation.h>

namespace spleeter {

class AudioProcessorDelegateImp : public IAudioProcessorDelegate {
public:
    AudioProcessorDelegateImp(__weak id<AudioProcessorViewDelegate> viewDelegate);

    virtual ~AudioProcessorDelegateImp();
    
    void onProgressUpdate(float progress) override;
    void onProcessingStart() override;
    void onProcessingFinish() override;
    void onProcessingError(const std::string& error) override;

private:
    __weak id<AudioProcessorViewDelegate> viewDelegate_;
};

} // namespace spleeter
