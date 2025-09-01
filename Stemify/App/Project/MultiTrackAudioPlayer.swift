//
//  MultiTrackAudioPlayer.swift
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/27.
//

import Foundation
import AVFoundation
import Combine

// MARK: - Weak Target for CADisplayLink
class WeakTarget {
    weak var target: MultiTrackAudioPlayer?
    
    init(target: MultiTrackAudioPlayer) {
        self.target = target
    }
    
    @objc func updateProgress() {
        target?.updateProgress()
    }
}

// MARK: - Audio Track Model
struct AudioTrack: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    var volume: Float = 1.0
    var isMuted: Bool = false
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
    }
}

// MARK: - Multi-Track Audio Player
class MultiTrackAudioPlayer: ObservableObject {
    // MARK: - Published Properties
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var tracks: [AudioTrack] = []
    
    // MARK: - Private Properties
    private let audioEngine = AVAudioEngine()
    private var playerNodes: [UUID: AVAudioPlayerNode] = [:]
    private var mixerNodes: [UUID: AVAudioMixerNode] = [:]
    private var audioFiles: [UUID: AVAudioFile] = [:]
    private var displayLink: CADisplayLink?
    private var startTime: TimeInterval = 0
    private var pausedTime: TimeInterval = 0
    
    // MARK: - Initialization
    init() {
        // Delay audio setup until tracks are loaded
    }
    
    deinit {
        stop()
        stopDisplayLink()
        clearNodes()
        
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    // MARK: - Public Methods
    func loadTracks(urls: [URL]) {
        stop()
        clearNodes()
        
        // Setup audio session and engine only when needed
        setupAudioSession()
        setupAudioEngine()
        
        var newTracks: [AudioTrack] = []
        var maxDuration: TimeInterval = 0
        
        for url in urls {
            do {
                let audioFile = try AVAudioFile(forReading: url)
                let track = AudioTrack(url: url)
                
                // Create player node and mixer node for this track
                let playerNode = AVAudioPlayerNode()
                let mixerNode = AVAudioMixerNode()
                
                // Store references
                playerNodes[track.id] = playerNode
                mixerNodes[track.id] = mixerNode
                audioFiles[track.id] = audioFile
                
                // Attach nodes to engine
                audioEngine.attach(playerNode)
                audioEngine.attach(mixerNode)
                
                // Connect: playerNode -> mixerNode -> mainMixerNode
                audioEngine.connect(playerNode, to: mixerNode, format: audioFile.processingFormat)
                audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: audioFile.processingFormat)
                
                // Calculate duration
                let trackDuration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
                maxDuration = max(maxDuration, trackDuration)
                
                newTracks.append(track)
                
            } catch {
                print("Failed to load audio file \(url.lastPathComponent): \(error)")
            }
        }
        
        // Prepare the engine only after nodes are connected
        if !newTracks.isEmpty {
            audioEngine.prepare()
        }
        
        Task { @MainActor in
            self.tracks = newTracks
            self.duration = maxDuration
            self.currentTime = 0
        }
    }
    
    func play() {
        guard !tracks.isEmpty else { return }
        
        do {
            if !audioEngine.isRunning {
                try audioEngine.start()
            }
            
            let startSampleTime = AVAudioFramePosition(pausedTime * 44100) // Assuming 44.1kHz sample rate
            
            for track in tracks {
                guard let playerNode = playerNodes[track.id],
                      let audioFile = audioFiles[track.id] else { continue }
                
                if !playerNode.isPlaying {
                    let remainingFrames = audioFile.length - startSampleTime
                    if remainingFrames > 0 {
                        playerNode.scheduleSegment(audioFile, 
                                                 startingFrame: startSampleTime, 
                                                 frameCount: AVAudioFrameCount(remainingFrames), 
                                                 at: nil)
                        playerNode.play()
                    }
                }
            }
            
            startTime = CACurrentMediaTime() - pausedTime
            startDisplayLink()
            
            Task { @MainActor in
                self.isPlaying = true
            }

        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func pause() {
        for playerNode in playerNodes.values {
            playerNode.pause()
        }
        
        pausedTime = currentTime
        stopDisplayLink()
        Task { @MainActor in
            self.isPlaying = false
        }
    }
    
    func stop() {
        for playerNode in playerNodes.values {
            playerNode.stop()
        }
        
        pausedTime = 0
        stopDisplayLink()
    }
    
    func seek(to time: TimeInterval) {
        let wasPlaying = isPlaying
        
        stop()
        pausedTime = min(max(time, 0), duration)
        
        Task { @MainActor in
            self.currentTime = self.pausedTime
        }
        
        if wasPlaying {
            play()
        }
    }
    
    func setVolume(for trackId: UUID, volume: Float) {
        guard let mixerNode = mixerNodes[trackId] else { return }
        
        mixerNode.outputVolume = volume
        
        Task { @MainActor in
            if let index = self.tracks.firstIndex(where: { $0.id == trackId }) {
                self.tracks[index].volume = volume
            }
        }
    }
    
    func setMute(for trackId: UUID, isMuted: Bool) {
        guard let mixerNode = mixerNodes[trackId] else { return }
        
        mixerNode.outputVolume = isMuted ? 0.0 : (tracks.first(where: { $0.id == trackId })?.volume ?? 1.0)
        
        Task { @MainActor in
            if let index = self.tracks.firstIndex(where: { $0.id == trackId }) {
                self.tracks[index].isMuted = isMuted
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupAudioEngine() {
        // The engine is already initialized, prepare will be called when tracks are loaded
    }
    
    private func clearNodes() {
        // Stop the engine if running
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // Stop all player nodes
        for playerNode in playerNodes.values {
            playerNode.stop()
            audioEngine.detach(playerNode)
        }
        
        // Detach all mixer nodes
        for mixerNode in mixerNodes.values {
            audioEngine.detach(mixerNode)
        }
        
        // Clear all dictionaries
        playerNodes.removeAll()
        mixerNodes.removeAll()
        audioFiles.removeAll()
    }
    
    private func startDisplayLink() {
        stopDisplayLink()
        displayLink = CADisplayLink(target: WeakTarget(target: self), selector: #selector(WeakTarget.updateProgress))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc func updateProgress() {
        guard isPlaying else { return }
        
        let elapsed = CACurrentMediaTime() - startTime
        let newTime = min(elapsed, duration)
        
        Task { @MainActor in
            self.currentTime = newTime
        }
        
        // Auto-stop when reaching the end
        if newTime >= duration {
            stop()
        }
    }
}
