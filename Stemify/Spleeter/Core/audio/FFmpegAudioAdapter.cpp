//
//  FFmpegAudioAdapter.cpp
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/19.
//
#include "FFmpegAudioAdapter.h"
#include "TFLiteInferenceEngine.h"

#include <algorithm>
#include <memory>

namespace spleeter {
#define MAX_AUDIO_FRAME_SIZE 192000  // 1 second of 48khz 32bit audio

namespace {
/// @brief Encode given frame to the media file
///
/// @param frame [in/out] - frame to be written to media file
/// @param audio_codec_context [in/out] - encoder context
/// @param format_context [in/out] - media format context
/// @param data_present [out] - writes 1 on encoded data is preset, 0 otherwise.
///
/// @return ret value - 0 on success, AVERROR (negative value) on error. Exception 0 on EOF.
static std::int32_t Encode(AVFrame* frame,
                           AVCodecContext* audio_codec_context,
                           AVFormatContext* format_context,
                           std::int32_t* data_present) {
    AVPacket* packet = av_packet_alloc();

    *data_present = 0;

    if (frame)
    {
        static std::int64_t pts{0};
        frame->pts = pts;
        pts += frame->nb_samples;
    }
    auto ret = avcodec_send_frame(audio_codec_context, frame);

    while (ret >= 0)
    {
        ret = avcodec_receive_packet(audio_codec_context, packet);
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF)
        {
            break;
        }


        *data_present = 1;
        packet->stream_index = 0;
        ret = av_write_frame(format_context, packet);
        av_packet_unref(packet);
    }

    av_packet_free(&packet);
    return 0;
}
} // name space

Waveform FFmpegAudioAdapter::Load(const std::string& path, const std::int32_t sample_rate) {
    ///
    /// Open Input Audio
    ///
    AVFormatContext* format_context = avformat_alloc_context();

    auto ret = avformat_open_input(&format_context, path.c_str(), nullptr, nullptr);

    ret = avformat_find_stream_info(format_context, nullptr);

    ret = av_find_best_stream(format_context, AVMEDIA_TYPE_AUDIO, -1, -1, nullptr, 0);
    auto stream_index = ret;
    AVStream* audio_stream = format_context->streams[stream_index];

    const AVCodec* audio_codec = avcodec_find_decoder(audio_stream->codecpar->codec_id);

    AVCodecContext* audio_codec_context = avcodec_alloc_context3(audio_codec);

    ret = avcodec_parameters_to_context(audio_codec_context, audio_stream->codecpar);

    ret = avcodec_open2(audio_codec_context, audio_codec, nullptr);

    av_dump_format(format_context, 0, path.c_str(), 0);

    ///
    /// Read Audio
    ///
    SwrContext* swr_context = swr_alloc();


    AVChannelLayout out_ch_layout = AV_CHANNEL_LAYOUT_STEREO;
    ret = swr_alloc_set_opts2(&swr_context,
                              &out_ch_layout,
                              AV_SAMPLE_FMT_FLT,
                              sample_rate,
                              &audio_codec_context->ch_layout,
                              audio_codec_context->sample_fmt,
                              audio_codec_context->sample_rate,
                              0,
                              nullptr);


    ret = swr_init(swr_context);


    std::uint8_t* buffer = (std::uint8_t*)av_malloc(MAX_AUDIO_FRAME_SIZE * 2);


    AVPacket* packet = av_packet_alloc();


    Waveform waveform{};
    std::int32_t nb_samples{0};
    while (av_read_frame(format_context, packet) >= 0) {
        AVFrame* frame = av_frame_alloc();

        ret = avcodec_send_packet(audio_codec_context, packet);
        while (ret >= 0) {
            ret = avcodec_receive_frame(audio_codec_context, frame);
            if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF)
            {
                break;
            }
            // Calculate maximum output samples (not bytes) that buffer can hold
            auto max_output_samples = (MAX_AUDIO_FRAME_SIZE * 2) / (sizeof(float) * 2); // stereo float samples

            // Convert audio samples - swr_convert expects sample count, not byte count
            auto converted_samples = swr_convert(swr_context, &buffer, max_output_samples, (const std::uint8_t**)frame->data, frame->nb_samples);

            if (converted_samples > 0) {
                // Cast buffer to float array and store samples (not bytes)
                float* float_buffer = reinterpret_cast<float*>(buffer);
                auto total_samples_to_store = converted_samples * 2; // stereo: samples * channels

                for (auto idx = 0; idx < total_samples_to_store; ++idx) {
                    waveform.data.push_back(float_buffer[idx]);
                }
            }

            nb_samples += converted_samples;
        }

        av_frame_free(&frame);
        av_packet_unref(packet);
    }
    /// Update Audio properties before releasing resources
    audio_properties_.nb_channels = audio_codec_context->ch_layout.nb_channels;
    audio_properties_.nb_frames = nb_samples;
    audio_properties_.sample_rate = sample_rate;
    waveform.nb_frames = audio_properties_.nb_frames;
    waveform.nb_channels = audio_properties_.nb_channels;

    av_packet_free(&packet);
    av_free(buffer);
    swr_free(&swr_context);
    avcodec_close(audio_codec_context);
    avformat_close_input(&format_context);

    return waveform;
}

void FFmpegAudioAdapter::Save(const std::string& path,
                              const Waveform& waveform,
                              const std::int32_t sample_rate,
                              const std::int32_t bitrate) {
    ///
    /// Open Output Audio
    ///
    AVFormatContext* format_context{nullptr};
    auto ret = avformat_alloc_output_context2(&format_context, nullptr, nullptr, path.c_str());

    if (!format_context) {
        return; // Failed to allocate format context
    }

    const AVOutputFormat* output_format = format_context->oformat;

    if (!output_format) {
        avformat_free_context(format_context);
        return; // No output format found
    }

    const AVCodec* audio_codec = avcodec_find_encoder(output_format->audio_codec);

    // If the default codec is not found, try to find MP3 encoder
    if (!audio_codec) {
        audio_codec = avcodec_find_encoder(AV_CODEC_ID_MP3);
    }

    // If still no codec found, return with error
    if (!audio_codec) {
        avformat_free_context(format_context);
        return; // or throw an exception
    }

    AVStream* audio_stream = avformat_new_stream(format_context, nullptr);

    if (!audio_stream) {
        avformat_free_context(format_context);
        return; // Failed to create audio stream
    }

    AVCodecContext* audio_codec_context = avcodec_alloc_context3(audio_codec);

    // Check if context allocation was successful
    if (!audio_codec_context) {
        avformat_free_context(format_context);
        return; // or throw an exception
    }

    ///
    /// Adjust Encoding Parameters
    ///
    audio_codec_context->codec_id = format_context->audio_codec_id;
    audio_codec_context->codec_type = AVMEDIA_TYPE_AUDIO;
    audio_codec_context->sample_fmt = AV_SAMPLE_FMT_FLTP;
    audio_codec_context->sample_rate =
        audio_codec->supported_samplerates ? audio_codec->supported_samplerates[0] : sample_rate;
    AVChannelLayout stereo_layout = AV_CHANNEL_LAYOUT_STEREO;
    av_channel_layout_copy(&audio_codec_context->ch_layout, &stereo_layout);
    audio_codec_context->bit_rate = bitrate;

    audio_stream->time_base = AVRational{1, sample_rate};

    if (output_format->flags & AVFMT_GLOBALHEADER)
    {
        audio_codec_context->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;
    }

    ///
    /// Open Codec
    ///
    ret = avcodec_open2(audio_codec_context, audio_codec, nullptr);

    ret = avcodec_parameters_from_context(audio_stream->codecpar, audio_codec_context);
    av_dump_format(format_context, 0, path.c_str(), 1);

    if (!(format_context->flags & AVFMT_NOFILE))
    {
        ret = avio_open(&format_context->pb, path.c_str(), AVIO_FLAG_WRITE);

    }

    if (audio_codec_context->codec &&
        (audio_codec_context->codec->capabilities & AV_CODEC_CAP_VARIABLE_FRAME_SIZE))
    {
        // Use a reasonable frame size (1024 samples is common for MP3)
        audio_codec_context->frame_size = 1152; // MP3 frame size
    }

    ///
    /// Allocate sample frame
    ///
    AVFrame* frame = av_frame_alloc();


    frame->nb_samples = audio_codec_context->frame_size;
    frame->format = audio_codec_context->sample_fmt;
    av_channel_layout_copy(&frame->ch_layout, &audio_codec_context->ch_layout);
    frame->sample_rate = audio_codec_context->sample_rate;

    ret = av_frame_get_buffer(frame, 0);

    ret = av_frame_make_writable(frame);

    // Note: No resampling needed as waveform.data is already in the target format


    ///
    /// Prepare for encoding (waveform.data is already in correct format)
    ///
    std::uint8_t** dst_data{nullptr};
    std::int32_t dst_linesize{0};
    // waveform.data.size() is the total samples, so nb_frames = total_samples / channels
    std::int32_t src_nb_samples = waveform.data.size() / 2; // Stereo: 2 channels

    ///
    /// Start encoding process
    ///
    ret = avformat_write_header(format_context, nullptr);

    ///
    /// Encode samples in batches
    ///
    std::int32_t samples_processed = 0;
    std::int32_t data_present{0};
    // Use waveform.data directly as it's already in float format
    const float* src_float_data = waveform.data.data();

    while (samples_processed < src_nb_samples) {
        // Calculate how many samples to process in this batch
        std::int32_t samples_this_batch = std::min(audio_codec_context->frame_size,
                                                   src_nb_samples - samples_processed);

        // Allocate frame buffer for this batch
        ret = av_samples_alloc_array_and_samples(&dst_data,
                                                 &dst_linesize,
                                                 audio_codec_context->ch_layout.nb_channels,
                                                 samples_this_batch,
                                                 audio_codec_context->sample_fmt,
                                                 0);

        // Copy data for this batch
        // waveform.data is interleaved stereo: [L0, R0, L1, R1, L2, R2, ...]
        // src_offset should be in terms of individual float samples (not frames)
        std::int32_t src_offset = samples_processed * 2; // 2 channels (stereo)

        if (audio_codec_context->sample_fmt == AV_SAMPLE_FMT_FLTP) {
            // Planar format: separate channels
            float* dst_left = reinterpret_cast<float*>(dst_data[0]);
            float* dst_right = reinterpret_cast<float*>(dst_data[1]);

            for (std::int32_t i = 0; i < samples_this_batch; ++i) {
                dst_left[i] = src_float_data[src_offset + i * 2];     // Left channel
                dst_right[i] = src_float_data[src_offset + i * 2 + 1]; // Right channel
            }
        } else {
            // Interleaved format
            std::int32_t bytes_to_copy = samples_this_batch * 2 * sizeof(float); // samples * channels * sizeof(float)
            std::memcpy(dst_data[0], src_float_data + src_offset, bytes_to_copy);
        }

        // Set up frame for encoding
        frame->nb_samples = samples_this_batch;
        frame->data[0] = dst_data[0];
        frame->data[1] = dst_data[1];

        // Encode this frame
        ret = Encode(frame, audio_codec_context, format_context, &data_present);

        // Free this batch's buffer
        av_freep(&dst_data[0]);
        av_freep(&dst_data);

        samples_processed += samples_this_batch;
    }

    ///
    /// Write queued samples
    ///
    data_present = 0;
    do {
        ret = Encode(nullptr, audio_codec_context, format_context, &data_present);
    } while (data_present);

    ret = av_write_trailer(format_context);

    ///
    /// Cleanup
    ///
    if (format_context && !(format_context->flags & AVFMT_NOFILE))
    {
        ret = avio_close(format_context->pb);

    }
    avcodec_close(audio_codec_context);
    av_frame_free(&frame);
    avcodec_free_context(&audio_codec_context);


}

AudioProperties FFmpegAudioAdapter::GetProperties() const {
    return audio_properties_;
}

}  // namespace spleeter
