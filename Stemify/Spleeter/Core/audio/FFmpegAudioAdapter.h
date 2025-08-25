//
//  FFmpegAudioAdapter.h
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/19.
//
#pragma once

#include "AudioProperties.h"
#include "WaveForm.h"

extern "C"
{
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/avutil.h>
#include <libavutil/frame.h>
#include <libavutil/mem.h>
#include <libavutil/opt.h>
#include <libswresample/swresample.h>
}

#include <algorithm>
#include <cstdint>
#include <string>
#include <utility>

namespace spleeter {
/// @brief An AudioAdapter implementation that use FFMPEG libraries to perform I/O operation for audio processing.
class FFmpegAudioAdapter {
  public:
    /// @brief Constructor.
    FFmpegAudioAdapter() = default;

    /// @brief Loads the audio file denoted by the given path and returns it data as a waveform.
    ///
    /// @param path [in]         - Path of the audio file to load data from.
    /// @param sample_rate [in]  - Sample rate to load audio with.
    ///
    /// @returns Loaded data as waveform
    Waveform Load(const std::string& path, const std::int32_t sample_rate);

    /// @brief Write waveform data to the file denoted by the given path using FFMPEG process.
    ///
    /// @param path [in]        - Path of the audio file to save data in.
    /// @param waveform [in]    - Waveform data to write.
    /// @param sample_rate [in] - Sample rate to write file in.
    /// @param bitrate [in]     - Bitrate of the written audio file.
    void Save(const std::string& path,
              const Waveform& waveform,
              const std::int32_t sample_rate,
              const std::int32_t bitrate);

    /// @brief Provide properties of the Waveform (nb_frames, nb_channels, sample_rate)
    ///
    /// @return audio properties
    AudioProperties GetProperties() const;

  private:
    /// @brief Loaded Audio Properties
    AudioProperties audio_properties_;
};
}  // namespace spleeter
