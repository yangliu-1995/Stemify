//
//  InferenceEngineParameters.h
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/19.
//
#pragma once

#include <string>
#include <vector>

namespace spleeter {

/// @brief InferenceEngine Parameters
struct InferenceEngineParameters {
    /// @brief Path to Model
    std::string model_path{};

    /// @brief Input Node/Tensor Name
    std::string input_tensor_name{};

    /// @brief List of Output Nodes/Tensors Name
    std::vector<std::string> output_tensor_names{};

    /// @brief Path to Model configurations
    std::string configuration{};
};

}  // namespace spleeter
