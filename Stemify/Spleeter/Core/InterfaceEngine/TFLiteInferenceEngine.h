//
//  TFLiteInferenceEngine.h
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/19.
//
#pragma once

#include <string>
#include <vector>

#import <TensorFlowLiteC/TensorFlowLiteC.h>

#include "InferenceEngineParameters.h"
#include "Waveform.h"

namespace spleeter {

class TFLiteInferenceEngine {
public:
    TFLiteInferenceEngine(const InferenceEngineParameters& params);
    ~TFLiteInferenceEngine();

    void Init();
    void Execute(const Waveform& waveform);
    void Shutdown();
    Waveforms GetResults() const;
    void ClearResults();
private:
    void UpdateInput(const Waveform& waveform);
    void UpdateTensors();
    void UpdateOutputs();
    Waveform ConvertToWaveform(TfLiteTensor *tensor);

    std::string model_path_;
    std::string input_tensor_name_;
    std::vector<std::string> output_tensor_names_;
    TfLiteInterpreter *interpreter_;
    Waveforms results_;
};
} // spleeter
