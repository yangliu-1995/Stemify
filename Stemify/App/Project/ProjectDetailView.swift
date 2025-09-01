//
//  ProjectDetailView.swift
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/27.
//

import SwiftUI

struct ProjectDetailView: View {
    let projectFolder: ProjectFolder
    @State private var audioFiles: [URL] = []
    @State private var isLoading = true
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: projectFolder.creationDate)
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Project Info Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "waveform")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(projectFolder.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Created: \(formattedDate)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Label("\(projectFolder.fileCount) tracks", systemImage: "music.note.list")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Label("Path: \(URL(fileURLWithPath: projectFolder.path).lastPathComponent)", systemImage: "folder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Audio Files Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Audio Files")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView("Loading audio files...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if audioFiles.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "music.note")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("No audio files found")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(audioFiles, id: \.self) { audioFile in
                            HStack {
                                Image(systemName: "waveform")
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(audioFile.lastPathComponent)
                                        .font(.body)
                                        .lineLimit(1)
                                    
                                    Text(audioFile.pathExtension.uppercased())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    playAudioFile(audioFile)
                                }) {
                                    Image(systemName: "play.circle")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Project Details")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadAudioFiles()
            }
        }
    }
    
    private func loadAudioFiles() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let projectURL = URL(fileURLWithPath: projectFolder.path)
            
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: projectURL,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles]
                )
                
                let audioExtensions = ["mp3", "wav", "m4a", "aac", "flac", "ogg"]
                let filteredFiles = contents.filter { url in
                    audioExtensions.contains(url.pathExtension.lowercased())
                }
                
                DispatchQueue.main.async {
                    self.audioFiles = filteredFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
                    self.isLoading = false
                }
            } catch {
                print("Failed to load audio files: \(error)")
                DispatchQueue.main.async {
                    self.audioFiles = []
                    self.isLoading = false
                }
            }
        }
    }
    
    private func playAudioFile(_ audioFile: URL) {
        // TODO: Implement audio playback functionality
        print("Playing audio file: \(audioFile.lastPathComponent)")
    }
}

struct ProjectDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectDetailView(
            projectFolder: ProjectFolder(
                name: "SpleeterProject_20240127_143052",
                path: "/Documents/SpleeterProject_20240127_143052",
                creationDate: Date(),
                fileCount: 3
            )
        )
    }
}