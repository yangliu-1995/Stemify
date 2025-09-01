//
//  WaveformView.swift
//  Stemify
//
//  Created by Assistant on 2024.
//

import SwiftUI
import AVFoundation

struct WaveformView: View {
    let audioURL: URL
    let progress: Double // 播放进度 0.0 - 1.0
    @State private var waveformData: [Float] = []
    @State private var isLoading = true
    @State private var viewWidth: CGFloat = 0
    
    private let barWidth: CGFloat = 2
    private let barSpacing: CGFloat = 1
    
    private var sampleCount: Int {
        guard viewWidth > 0 else { return 50 }
        return max(10, Int(viewWidth / (barWidth + barSpacing)))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isLoading {
                    // 加载状态
                    HStack(spacing: barSpacing) {
                        ForEach(0..<min(20, sampleCount), id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: barWidth, height: CGFloat.random(in: 4...20))
                        }
                    }
                    .frame(height: 30)
                } else {
                    // 波形显示
                    HStack(alignment: .center, spacing: barSpacing) {
                        ForEach(Array(waveformData.enumerated()), id: \.offset) { index, amplitude in
                            let isPlayed = Double(index) / Double(waveformData.count) <= progress
                            let barHeight = max(2, CGFloat(amplitude) * 28)
                            
                            RoundedRectangle(cornerRadius: 0.5)
                                .fill(isPlayed ? Color.blue : Color.gray.opacity(0.4))
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
            .onChange(of: geometry.size.width) { newWidth in
                if abs(newWidth - viewWidth) > 10 { // 避免频繁更新
                    viewWidth = newWidth
                    loadWaveform()
                }
            }
        }
    }
    
    private func loadWaveform() {
        Task {
            do {
                let waveform = try await generateWaveform(from: audioURL)
                await MainActor.run {
                    self.waveformData = waveform
                    self.isLoading = false
                }
            } catch {
                print("Failed to generate waveform: \(error)")
                await MainActor.run {
                    // 生成默认波形数据
                    self.waveformData = (0..<sampleCount).map { _ in Float.random(in: 0.1...1.0) }
                    self.isLoading = false
                }
            }
        }
    }
    
    private func generateWaveform(from url: URL) async throws -> [Float] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let audioFile = try AVAudioFile(forReading: url)
                    let format = audioFile.processingFormat
                    let frameCount = AVAudioFrameCount(audioFile.length)
                    
                    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                        continuation.resume(throwing: WaveformError.bufferCreationFailed)
                        return
                    }
                    
                    try audioFile.read(into: buffer)
                    
                    guard let channelData = buffer.floatChannelData?[0] else {
                        continuation.resume(throwing: WaveformError.noChannelData)
                        return
                    }
                    
                    let samplesPerPoint = Int(frameCount) / sampleCount
                    var waveform: [Float] = []
                    
                    for i in 0..<sampleCount {
                        let startIndex = i * samplesPerPoint
                        let endIndex = min(startIndex + samplesPerPoint, Int(frameCount))
                        
                        var maxAmplitude: Float = 0
                        for j in startIndex..<endIndex {
                            maxAmplitude = max(maxAmplitude, abs(channelData[j]))
                        }
                        
                        waveform.append(maxAmplitude)
                    }
                    
                    continuation.resume(returning: waveform)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

enum WaveformError: Error {
    case bufferCreationFailed
    case noChannelData
}

struct WaveformView_Previews: PreviewProvider {
    static var previews: some View {
        WaveformView(audioURL: URL(fileURLWithPath: "/path/to/sample.mp3"), progress: 0.5)
            .padding()
    }
}
