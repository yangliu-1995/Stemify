//
//  TrackControlView.swift
//  Stemify
//
//  Created by Assistant on 2024.
//

import SwiftUI

struct TrackControlView: View {
    let track: AudioTrack
    @EnvironmentObject var player: MultiTrackAudioPlayer

    @State private var volume: Float
    @State private var isMuted: Bool

    @Environment(\.cardCornerRadius) private var cardCornerRadius

    private let audioWaveformGenerator: AudioWaveformGenerator

    init(audioWaveformGenerator: AudioWaveformGenerator, track: AudioTrack) {
        self.audioWaveformGenerator = audioWaveformGenerator
        self.track = track
        self._volume = State(initialValue: track.volume)
        self._isMuted = State(initialValue: track.isMuted)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Track Header
            HStack {
                Text(track.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                // Share Button
                ShareLink(item: track.url) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title3)
                        .foregroundColor(Color(.label))
                }
                
                // Mute Button
                Button(action: {
                    isMuted.toggle()
                    player.setMute(for: track.id, isMuted: isMuted)
                }) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.2.fill")
                        .font(.title3)
                        .foregroundColor(isMuted ? .red : Color(.label))
                }
            }
            
            // Waveform Display
            WaveformView(audioWaveformGenerator: audioWaveformGenerator, progress: $player.progress)
                .frame(height: 40)
                .background(Color(.systemGray6))
                .cornerRadius(6)

            // Volume Control
            HStack {
                Image(systemName: "speaker.1")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(value: Binding(
                    get: { volume },
                    set: { newValue in
                        volume = newValue
                        player.setVolume(for: track.id, volume: volume)
                    }
                ), in: 0...1)
                .disabled(isMuted)
                .opacity(isMuted ? 0.5 : 1.0)
                
                Image(systemName: "speaker.3")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(Int(volume * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 35)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(cardCornerRadius)
    }
}
