//
//  MultiTrackPlayerView.swift
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/27.
//

import SwiftUI

struct MultiTrackPlayerView: View {
    @StateObject private var player = MultiTrackAudioPlayer()
    let audioUrls: [URL]
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Player Controls
            VStack(spacing: 12) {
                // Progress Bar
                VStack(spacing: 8) {
                    HStack {
                        Text(formatTime(player.currentTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatTime(player.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: Binding(
                        get: { player.currentTime },
                        set: { newValue in
                            player.seek(to: newValue)
                        }
                    ), in: 0...max(1, player.duration))
                    .accentColor(.blue)

                }
                
                // Play/Pause Button with Skip Controls
                HStack(spacing: 20) {
                    // Rewind 15 seconds
                    Button(action: {
                        player.seek(to: max(0, player.currentTime - 15))
                    }) {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        if player.isPlaying {
                            player.pause()
                        } else {
                            player.play()
                        }
                    }) {
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    }
                    
                    // Fast forward 15 seconds
                    Button(action: {
                        player.seek(to: min(player.duration, player.currentTime + 15))
                    }) {
                        Image(systemName: "goforward.15")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Individual Track Controls
            LazyVStack(spacing: 12) {
                ForEach(player.tracks) { track in
                    TrackControlView(
                        track: track,
                        progress: player.duration > 0 ? player.currentTime / player.duration : 0.0,
                        onVolumeChange: { volume in
                            player.setVolume(for: track.id, volume: volume)
                        },
                        onMuteToggle: { isMuted in
                            player.setMute(for: track.id, isMuted: isMuted)
                        }
                    )
                }
            }
        }
        .onAppear {
            player.loadTracks(urls: audioUrls)
        }
        .onDisappear {
            player.stop()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}



struct MultiTrackPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        MultiTrackPlayerView(audioUrls: [
            URL(fileURLWithPath: "/path/to/track1.mp3"),
            URL(fileURLWithPath: "/path/to/track2.mp3"),
            URL(fileURLWithPath: "/path/to/track3.mp3")
        ])
        .padding()
    }
}
