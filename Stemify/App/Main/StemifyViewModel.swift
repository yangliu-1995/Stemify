import Foundation
import Combine
import UniformTypeIdentifiers

@MainActor
class StemifyViewModel: ObservableObject {
    // Published properties for UI binding
    @Published var fileName: String = "Please select an audio file"
    @Published var isProcessing: Bool = false
    @Published var progress: Float = 0.0
    @Published var status: String = "Waiting to start"
    @Published var timeInfo: String = ""
    @Published var isStartButtonEnabled: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var selectedModel: Spleeter.Model = .model2Stems // Default model

    private var selectedFileURL: URL?
    private var progressStart: TimeInterval = 0.0
    private var currentProjectPath: String?
    private let spleeter = Spleeter.shared

    // Handle file selection
    func selectFile(url: URL) {
        // Start accessing security-scoped resource
        let accessing = url.startAccessingSecurityScopedResource()
        if accessing {
            selectedFileURL = url
            fileName = "Selected: \(url.lastPathComponent)"
            isStartButtonEnabled = true
            print("Selected file: \(url.path)")
        } else {
            alertTitle = "Error"
            alertMessage = "Unable to access the selected file"
            showAlert = true
        }
    }

    // Create project folder name based on selected file
    private func createProjectFolderName(for fileURL: URL) -> String {
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        let baseName = "\(fileName).stemifyproj"
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var finalName = baseName
        var counter = 1
        
        // Check if folder exists and add number suffix if needed
        while FileManager.default.fileExists(atPath: documentsPath.appendingPathComponent(finalName).path) {
            finalName = "\(fileName)(\(counter)).stemifyproj"
            counter += 1
        }
        
        return finalName
    }

    // Process audio file
    func processAudio() {
        // Check if already processing
        if isProcessing {
            alertTitle = "Processing in Progress"
            alertMessage = "Audio processing is already in progress. Please wait for it to complete."
            showAlert = true
            return
        }
        
        guard let fileURL = selectedFileURL else {
            alertTitle = "Error"
            alertMessage = "Please select an audio file first"
            showAlert = true
            return
        }

        // Create project folder
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let projectFolderName = createProjectFolderName(for: fileURL)
        let projectPath = documentsPath.appendingPathComponent(projectFolderName)

        do {
            try FileManager.default.createDirectory(at: projectPath, withIntermediateDirectories: true)
            currentProjectPath = projectPath.path()
            print("Project folder created successfully: \(projectPath.path)")
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to create project folder: \(error.localizedDescription)"
            showAlert = true
            print("Failed to create project folder: \(error.localizedDescription)")
            return
        }

        // Start processing
        isProcessing = true
        isStartButtonEnabled = false
        progress = 0.0
        status = "Starting..."
        timeInfo = "Preparing..."
        progressStart = Date().timeIntervalSince1970

        // Decode the project path to remove URL encoding before passing to FFmpeg
        let originalPath = projectPath.path()
        let decodedProjectPath = originalPath.removingPercentEncoding ?? originalPath

#if DEBUG
        print("📁 Original project path: \(originalPath)")
        print("📁 Decoded project path: \(decodedProjectPath)")
#endif

        spleeter.processFile(
            at: fileURL.path,
            using: selectedModel, // Use selected model
            saveAt: decodedProjectPath,
            onStart: { [weak self] in
                self?.status = "Starting..."
                self?.timeInfo = "Preparing..."
            },
            onProgress: { [weak self] progress in
                guard let self else { return }
                self.progress = progress
                self.status = "Processing..."

                // Estimate remaining time
                if progress > 0.05 { // Start estimating after 5%
                    let elapsed = Date().timeIntervalSince1970 - self.progressStart
                    let estimatedTotal = elapsed / Double(progress)
                    let remaining = estimatedTotal - elapsed
                    if remaining > 0 {
                        self.timeInfo = String(format: "Estimated remaining: %.0f seconds", remaining * 1.1)
                    }
                }
            },
            onCompletion: { [weak self] success, error in
                guard let self else { return }
                if success {
                    let elapsed = Date().timeIntervalSince1970 - self.progressStart
                    self.progress = 1.0
                    self.status = "Processing completed!"
                    self.timeInfo = String(format: "Total time: %.1f seconds", elapsed)
                    self.isStartButtonEnabled = true
                    self.isProcessing = false

                    // Stop accessing security-scoped resource
                    self.selectedFileURL?.stopAccessingSecurityScopedResource()

                    // Show completion alert
                    if let currentProjectPath = self.currentProjectPath {
                        let folderName = (currentProjectPath as NSString).lastPathComponent
                        self.alertTitle = "Processing Completed"
                        self.alertMessage = "Audio separation finished in \(elapsed) seconds.\nResults saved in project folder: \(folderName)"
                        self.showAlert = true
                    }
                } else {
                    self.status = "Processing failed"
                    self.timeInfo = ""
                    self.isStartButtonEnabled = true
                    self.isProcessing = false

                    // Stop accessing security-scoped resource
                    self.selectedFileURL?.stopAccessingSecurityScopedResource()
                    self.currentProjectPath = nil

                    // Show error alert
                    self.alertTitle = "Processing Failed"
                    self.alertMessage = error?.localizedDescription ?? "Failed"
                    self.showAlert = true
                }
            }
        )
    }
}
