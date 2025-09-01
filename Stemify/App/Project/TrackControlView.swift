//
//  TrackControlView.swift
//  Stemify
//
//  Created by Assistant on 2024.
//

import SwiftUI

struct TrackControlView: View {
    let track: AudioTrack
    let progress: Double // 播放进度 0.0 - 1.0
    let onVolumeChange: (Float) -> Void
    let onMuteToggle: (Bool) -> Void
    
    @State private var volume: Float
    @State private var isMuted: Bool

    @Environment(\.cardCornerRadius) private var cardCornerRadius

    init(track: AudioTrack, progress: Double = 0.0, onVolumeChange: @escaping (Float) -> Void, onMuteToggle: @escaping (Bool) -> Void) {
        self.track = track
        self.progress = progress
        self.onVolumeChange = onVolumeChange
        self.onMuteToggle = onMuteToggle
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
                    onMuteToggle(isMuted)
                }) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.2.fill")
                        .font(.title3)
                        .foregroundColor(isMuted ? .red : Color(.label))
                }
            }
            
            // Waveform Display
            WaveformView(audioURL: track.url, progress: progress)
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
                        onVolumeChange(newValue)
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

struct TrackControlView_Previews: PreviewProvider {
    static var previews: some View {
        TrackControlView(
            track: AudioTrack(url: URL(fileURLWithPath: "/path/to/sample.mp3")),
            progress: 0.3,
            onVolumeChange: { _ in },
            onMuteToggle: { _ in }
        )
        .padding()
    }
}
