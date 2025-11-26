//
//  AudioWaveformGenerator.swift
//  Stemify
//
//  Created by XueyuanXiao on 11/26/25.
//


import AVFoundation
import Foundation

/// Waveform generator dedicated to a single audio file
/// - Binds the audio URL at init time
/// - Generates a high-resolution waveform only once (2000 points)
/// - Subsequent calls to getWaveform(points:) are instant thanks to caching
/// - Thread-safe (actor), extremely low memory usage, works with hours-long files
actor AudioWaveformGenerator {
    
    private let url: URL
    private var cachedHighResWaveform: [Float]? = nil
    
    /// Fixed number of samples used for the internal high-resolution waveform
    private let highResolutionCount = 2000
    
    /// Initialize with the audio file you want to analyse
    /// - Parameter audioURL: Local file URL of the audio
    init(audioURL: URL) {
        self.url = audioURL
    }
    
    /// Main public method – get a waveform with any number of points
    /// - Parameter points: Desired number of samples (e.g. 100, 800, 1500 …). Default = 200
    /// - Returns: Normalized [Float] array in range 0.0 to 1.0
    func getWaveform(points: Int = 200) async throws -> [Float] {
        try await generateIfNeeded()
        return resample(to: points)
    }
    
    /// Generates the high-resolution waveform only if it hasn't been generated yet
    private func generateIfNeeded() async throws {
        if cachedHighResWaveform != nil {
            return
        }
        
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat
        let totalFrames = audioFile.length
        
        // Empty or silent file → return zero waveform
        guard totalFrames > 0 else {
            cachedHighResWaveform = Array(repeating: 0.0, count: highResolutionCount)
            return
        }
        
        let channelCount = Int(format.channelCount)
        let bufferSize: AVAudioFrameCount = 8192
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else {
            throw NSError(domain: "AudioWaveformGenerator", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create PCM buffer"])
        }
        
        var waveform = [Float](repeating: 0.0, count: highResolutionCount)
        var globalMaxAmplitude: Float = .leastNonzeroMagnitude
        
        /// Returns the frame position that corresponds to a given high-resolution index
        func framePosition(for index: Int) -> Int64 {
            Int64((Double(totalFrames) * Double(index)) / Double(highResolutionCount))
        }
        
        var currentBinIndex = 0
        var nextBinFrameBoundary = framePosition(for: 1)
        
        audioFile.framePosition = 0
        
        // Stream the file in small chunks to keep memory usage tiny
        while audioFile.framePosition < totalFrames {
            let framesToRead = min(bufferSize, AVAudioFrameCount(totalFrames - audioFile.framePosition))
            buffer.frameLength = framesToRead
            try audioFile.read(into: buffer)
            
            guard let channelData = buffer.floatChannelData else { continue }
            
            for i in 0..<Int(buffer.frameLength) {
                // Average absolute value across all channels (more accurate than single channel)
                var sumAbs: Float = 0.0
                for ch in 0..<channelCount {
                    sumAbs += abs(channelData[ch][i])
                }
                let averageAbs = sumAbs / Float(channelCount)
                
                // Track global peak for later normalisation
                globalMaxAmplitude = max(globalMaxAmplitude, averageAbs)
                
                // Calculate absolute frame position in the whole file
                let currentFramePos = audioFile.framePosition + Int64(i) - Int64(framesToRead)
                
                // Move forward to the correct bin if we crossed a boundary
                while currentFramePos >= nextBinFrameBoundary && currentBinIndex < highResolutionCount - 1 {
                    currentBinIndex += 1
                    nextBinFrameBoundary = framePosition(for: currentBinIndex + 1)
                }
                
                // Update peak for the current bin
                waveform[currentBinIndex] = max(waveform[currentBinIndex], averageAbs)
            }
        }
        
        // Normalise to 0.0–1.0 range
        if globalMaxAmplitude > 0 {
            for i in 0..<highResolutionCount {
                waveform[i] /= globalMaxAmplitude
            }
        }
        
        cachedHighResWaveform = waveform
    }
    
    /// Resample the internal 2000-point waveform to any target point count
    private func resample(to targetCount: Int) -> [Float] {
        guard let source = cachedHighResWaveform, !source.isEmpty else {
            return Array(repeating: 0.0, count: max(1, targetCount))
        }
        
        // Upsampling → linear interpolation
        if targetCount >= highResolutionCount {
            return linearInterpolate(source: source, to: targetCount)
        }
        
        // Downsampling → combine multiple source points into one, keeping the maximum (preserves peaks)
        var result = [Float](repeating: 0.0, count: targetCount)
        let ratio = Double(highResolutionCount) / Double(targetCount)
        
        for i in 0..<targetCount {
            let start = Int(Double(i) * ratio)
            let end = Int(Double(i + 1) * ratio)
            let slice = source[start..<min(end, highResolutionCount)]
            result[i] = slice.max() ?? 0.0
        }
        return result
    }
    
    /// Linear interpolation – used when target point count > 2000
    private func linearInterpolate(source: [Float], to targetCount: Int) -> [Float] {
        var result = [Float](repeating: 0.0, count: targetCount)
        let ratio = Double(highResolutionCount - 1) / Double(targetCount - 1)
        
        for i in 0..<targetCount {
            let pos = Double(i) * ratio
            let idx = Int(pos)
            let fraction = Float(pos - Double(idx))
            
            if idx + 1 < highResolutionCount {
                let a = source[idx]
                let b = source[idx + 1]
                result[i] = a + fraction * (b - a)
            } else {
                result[i] = source.last ?? 0.0
            }
        }
        return result
    }
    
    /// Clear cached waveform – call when switching to a new audio file
    func clearCache() {
        cachedHighResWaveform = nil
    }
}
