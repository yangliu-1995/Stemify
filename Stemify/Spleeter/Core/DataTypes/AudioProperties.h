//
//  AudioProperties.h
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/19.
//
#pragma once

#include <cstdint>
#include <ostream>

namespace spleeter {
/// @brief Audio Properties
struct AudioProperties {
    /// @brief Number of frames/samples
    std::uint64_t nb_frames;

    /// @brief Number of channels
    std::uint64_t nb_channels;

    /// @brief Sample Rate
    std::uint32_t sample_rate;
};

/// @brief Prepare output stream for AudioProperties
inline std::ostream& operator<<(std::ostream& out, const AudioProperties& audio_properties) {
    out << "AudioProperties{nb_channels: " << audio_properties.nb_channels
        << ", nb_frames: " << audio_properties.nb_frames << ", sample_rate: " << audio_properties.sample_rate << "}";
    return out;
}
}  // namespace spleeter
