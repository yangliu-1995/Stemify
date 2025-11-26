//
//  WaveformView.swift
//  Stemify
//
//  Created by Assistant on 2024.
//

import SwiftUI
import AVFoundation

struct WaveformView: View {
    @Binding var progress: Double // Playback progress 0.0 - 1.0
    @State private var waveformData: [Float] = []
    @State private var isLoading = true
    @State private var viewWidth: CGFloat = 0
    
    private let barWidth: CGFloat = 2
    private let barSpacing: CGFloat = 1

    private let audioWaveformGenerator: AudioWaveformGenerator

    private var sampleCount: Int {
        guard viewWidth > 0 else { return 50 }
        return max(10, Int(viewWidth / (barWidth + barSpacing)))
    }

    init(audioWaveformGenerator: AudioWaveformGenerator, progress: Binding<Double>) {
        self._progress = progress
        self.audioWaveformGenerator = audioWaveformGenerator
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isLoading {
                    // Loading state
                    HStack(spacing: barSpacing) {
                        ForEach(0..<sampleCount, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: barWidth, height: 4)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    // Waveform display
                    HStack(alignment: .center, spacing: barSpacing) {
                        ForEach(Array(waveformData.enumerated()), id: \.offset) { index, amplitude in
                            let isPlayed = Double(index) / Double(waveformData.count) <= progress
                            let barHeight = max(2, CGFloat(amplitude) * 28)
                            
                            RoundedRectangle(cornerRadius: 0.5)
                                .fill(isPlayed ? Color(.label) : Color.gray.opacity(0.4))
                                .frame(
                                    width: barWidth,
                                    height: barHeight
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .onAppear {
                viewWidth = geometry.size.width
                loadWaveform()
            }
            .onChange(of: geometry.size.width) { _, newWidth in
                if abs(newWidth - viewWidth) > 10 { // Avoid frequent updates
                    viewWidth = newWidth
                    loadWaveform()
                }
            }
        }
    }
    
    private func loadWaveform() {
        Task(priority: .high) {
            do {
                let waveform = try await audioWaveformGenerator.getWaveform(points: sampleCount)
                await MainActor.run {
                    self.waveformData = waveform
                    self.isLoading = false
                }
            } catch {
                print("Failed to generate waveform: \(error)")
                await MainActor.run {
                    // Generate default waveform data
                    self.waveformData = (0..<sampleCount).map { _ in Float.random(in: 0.1...1.0) }
                    self.isLoading = false
                }
            }
        }
    }
}
