//
//  TFLiteInferenceEngine.mm
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/19.
//

#include "TFLiteInferenceEngine.h"
#include <iostream>

namespace spleeter {
TFLiteInferenceEngine::TFLiteInferenceEngine(const InferenceEngineParameters& params)
    : model_path_(params.model_path),
      input_tensor_name_(params.input_tensor_name),
      output_tensor_names_(params.output_tensor_names),
      interpreter_(nullptr),
      results_() {
}

TFLiteInferenceEngine::~TFLiteInferenceEngine() {
    Shutdown();
}

void TFLiteInferenceEngine::Init() {
    TfLiteModel* model = TfLiteModelCreateFromFile(model_path_.c_str());
    if (!model) {
        std::cerr << "Failed to create model from file: " << model_path_ << std::endl;
        return;
    }

    TfLiteInterpreterOptions* options = TfLiteInterpreterOptionsCreate();
    TfLiteInterpreterOptionsSetNumThreads(options, 2);
    // Note: XNNPACK is enabled by default in TFLite C API if available, no explicit setting needed

    interpreter_ = TfLiteInterpreterCreate(model, options);
    if (!interpreter_) {
        std::cerr << "Failed to create interpreter" << std::endl;
        TfLiteModelDelete(model);
        TfLiteInterpreterOptionsDelete(options);
        return;
    }

    if (TfLiteInterpreterAllocateTensors(interpreter_) != kTfLiteOk) {
        std::cerr << "Failed to allocate tensors" << std::endl;
        TfLiteInterpreterDelete(interpreter_);
        TfLiteModelDelete(model);
        TfLiteInterpreterOptionsDelete(options);
        interpreter_ = nullptr;
        return;
    }

    std::cout << "Successfully loaded TensorFlow Lite model from " << model_path_ << std::endl;

    // Clean up model and options as they're no longer needed
    TfLiteModelDelete(model);
    TfLiteInterpreterOptionsDelete(options);
}

void TFLiteInferenceEngine::Execute(const Waveform& waveform) {
    UpdateInput(waveform);
    UpdateTensors();
    UpdateOutputs();
}

void TFLiteInferenceEngine::UpdateInput(const Waveform& waveform) {

    // Get input tensor
    TfLiteTensor* input_tensor = TfLiteInterpreterGetInputTensor(interpreter_, 0);
    if (!input_tensor) {
        std::cerr << "Failed to get input tensor" << std::endl;
        return;
    }

    // Resize input tensor
    std::vector<int> dims = {waveform.nb_frames, waveform.nb_channels};
    if (TfLiteInterpreterResizeInputTensor(interpreter_, 0, dims.data(), dims.size()) != kTfLiteOk) {
        std::cerr << "Failed to resize input tensor" << std::endl;
        return;
    }

    // Allocate tensors after resizing
    if (TfLiteInterpreterAllocateTensors(interpreter_) != kTfLiteOk) {
        std::cerr << "Failed to allocate tensors" << std::endl;
        return;
    }

    // Copy data to input tensor
    const void* bytes = waveform.data.data();
    size_t length = waveform.nb_frames * waveform.nb_channels * sizeof(float);

    if (TfLiteTensorCopyFromBuffer(input_tensor, bytes, length) != kTfLiteOk) {
        std::cerr << "Failed to copy data to input tensor" << std::endl;
        return;
    }

    std::cout << "Successfully loaded input waveform: Waveform{nb_frames: " << waveform.nb_frames
              << ", nb_channels: " << waveform.nb_channels << ", nb_size: " << waveform.data.size() << "}" << std::endl;
}

void TFLiteInferenceEngine::UpdateTensors() {

    if (TfLiteInterpreterInvoke(interpreter_) != kTfLiteOk) {
        std::cerr << "Failed to invoke interpreter" << std::endl;
        return;
    }

    int output_count = TfLiteInterpreterGetOutputTensorCount(interpreter_);
    std::cout << "Successfully invoked interpreter with " << output_count << " outputs" << std::endl;
}

void TFLiteInferenceEngine::UpdateOutputs() {
    results_.clear();

    for (int i = 0; i < TfLiteInterpreterGetOutputTensorCount(interpreter_); i++) {
        TfLiteTensor* output_tensor = (TfLiteTensor *)TfLiteInterpreterGetOutputTensor(interpreter_, i);
        if (!output_tensor) {
            std::cerr << "Failed to get output tensor at index " << i << std::endl;
            continue;
        }

        Waveform waveform = ConvertToWaveform(output_tensor);
        results_.push_back(waveform);
    }

    std::cout << results_ << std::endl;
}

Waveform TFLiteInferenceEngine::ConvertToWaveform(TfLiteTensor *tensor) {
    const TfLiteTensor* tf_tensor = (const TfLiteTensor *)tensor;

    // Get tensor dimensions
    int num_dims = TfLiteTensorNumDims(tf_tensor);
    int32_t samples = num_dims > 0 ? TfLiteTensorDim(tf_tensor, 0) : 1;
    int32_t channels = num_dims > 1 ? TfLiteTensorDim(tf_tensor, 1) : 1;

    // Get tensor data
    const float* data_ptr = (const float*)TfLiteTensorData(tf_tensor);
    if (!data_ptr) {
        std::cerr << "Failed to get tensor data" << std::endl;
        return Waveform{0, 0, {}};
    }

    size_t data_size = TfLiteTensorByteSize(tf_tensor) / sizeof(float);

    Waveform waveform;
    waveform.nb_frames = samples;
    waveform.nb_channels = channels;
    waveform.data.assign(data_ptr, data_ptr + data_size);
    return waveform;
}

void TFLiteInferenceEngine::Shutdown() {
    if (interpreter_) {
        TfLiteInterpreterDelete((TfLiteInterpreter *)interpreter_);
        interpreter_ = nullptr;
    }
    results_.clear();
}

Waveforms TFLiteInferenceEngine::GetResults() const {
    return results_;
}

void TFLiteInferenceEngine::ClearResults() {
    results_.clear();
}

} // spleeter
