//
//  ViewController.swift
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/25.
//

import UIKit
import UniformTypeIdentifiers

class ViewController: UIViewController {

    private let selectFileButton = UIButton(type: .system)
    private let startButton = UIButton(type: .system)
    private let progressView = UIProgressView()
    private let statusLabel = UILabel()
    private let timeLabel = UILabel()
    private let fileNameLabel = UILabel()

    private var selectedFileURL: URL?
    private var progressStart = Date().timeIntervalSince1970
    private var currentProjectPath: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        createUIElements()

        setupConstraints()

        updateUIState()
    }

    private func createUIElements() {
        // File name label
        fileNameLabel.text = "Please select an audio file"
        fileNameLabel.textAlignment = .center
        fileNameLabel.font = UIFont.systemFont(ofSize: 16)
        fileNameLabel.textColor = .secondaryLabel
        fileNameLabel.numberOfLines = 2
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fileNameLabel)

        // Select file button
        selectFileButton.setTitle("Select Audio File", for: .normal)
        selectFileButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        selectFileButton.setTitleColor(.systemBlue, for: .normal)
        selectFileButton.addTarget(self, action: #selector(selectFileAction(_:)), for: .touchUpInside)
        selectFileButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(selectFileButton)

        // Start button
        startButton.setTitle("Start Processing", for: .normal)
        startButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        startButton.setTitleColor(.white, for: .normal)
        startButton.backgroundColor = .systemGreen
        startButton.layer.cornerRadius = 8
        startButton.isEnabled = false
        startButton.addTarget(self, action: #selector(startProcessing(_:)), for: .touchUpInside)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startButton)

        // Status label
        statusLabel.text = "Waiting to start"
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 16)
        statusLabel.textColor = .label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // Progress bar
        progressView.progress = 0.0
        progressView.progressTintColor = .systemBlue
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)

        // Time label
        timeLabel.text = ""
        timeLabel.textAlignment = .center
        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.textColor = .secondaryLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timeLabel)
    }

    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // File name label
            fileNameLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 40),
            fileNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            fileNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Select file button
            selectFileButton.topAnchor.constraint(equalTo: fileNameLabel.bottomAnchor, constant: 20),
            selectFileButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectFileButton.widthAnchor.constraint(equalToConstant: 200),
            selectFileButton.heightAnchor.constraint(equalToConstant: 44),

            // Start button
            startButton.topAnchor.constraint(equalTo: selectFileButton.bottomAnchor, constant: 30),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 200),
            startButton.heightAnchor.constraint(equalToConstant: 50),

            // Status label
            statusLabel.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 40),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Progress bar
            progressView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            progressView.heightAnchor.constraint(equalToConstant: 4),

            // Time label
            timeLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 20),
            timeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func updateUIState() {
        startButton.isEnabled = (selectedFileURL != nil)
        if selectedFileURL != nil {
            startButton.backgroundColor = .systemGreen
        } else {
            startButton.backgroundColor = .systemGray
        }
    }

    // actions
    @objc private func selectFileAction(_ sender: UIButton) {
        let audioTypes: [UTType] = [.audio]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: audioTypes)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet

        present(documentPicker, animated: true, completion: nil)
    }

    @objc private func startProcessing(_ sender: UIButton) {
        guard let _ = selectedFileURL else {
            showAlert(title: "Error", message: "Please select an audio file first")
            return
        }

        // Start processing audio
        processSelectedFile()
    }

    func processSelectedFile() {
        guard let fileURL = selectedFileURL else { return }

        // Process audio on a background thread
        DispatchQueue.global(qos: .default).async {
            self.doActWithFile(fileURL.path)
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)

        self.present(alert, animated: true, completion: nil)
    }

    private func createProjectFolderName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return "SpleeterProject_\(timestamp)"
    }

    private func doActWithFile(_ path: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let projectFolderName = createProjectFolderName()
        let projectPath = documentsPath.appendingPathComponent(projectFolderName)

        do {
            try FileManager.default.createDirectory(at: projectPath, withIntermediateDirectories: true, attributes: nil)
            print("Project folder created successfully: \(projectPath.path)")
        } catch {
            print("Failed to create project folder: \(error.localizedDescription)")
        }
        currentProjectPath = projectPath.path()
        
        SpleeterIOS.shared.processFile(at: path, using: .model2Stems, saveAt: projectPath.path()) { [weak self] in
            guard let self else {
                return
            }
            self.progressView.progress = 0.0
            self.statusLabel.text = "Starting..."
            self.timeLabel.text = "Preparing..."
            self.startButton.isEnabled = false
            self.selectFileButton.isEnabled = false
            self.startButton.setTitle("Processing...", for: .normal)
            self.startButton.backgroundColor = .systemGray
            self.progressStart = Date().timeIntervalSince1970
        } onProgress: { [weak self] progress in
            guard let self else {
                return
            }
            self.progressView.progress = progress
            self.statusLabel.text = String(format: "Processing... %.1f%%", progress * 100.0)

            // Estimate remaining time
            if progress > 0.05 { // Start estimating after 5%
                let elapsed = Date().timeIntervalSince1970 - progressStart
                let estimatedTotal = elapsed / Double(progress)
                let remaining = estimatedTotal - elapsed

                if remaining > 0 {
                    self.timeLabel.text = String(format: "Estimated remaining: %.0f seconds", remaining * 1.1)
                }
            }
        } onCompletion: { [weak self] success, error in
            guard let self else {
                return
            }
            if success {
                let elapsed = Date().timeIntervalSince1970 - self.progressStart
                self.progressView.progress = 1.0
                self.statusLabel.text = "Processing completed!"
                self.timeLabel.text = String(format: "Total time: %.1f seconds", elapsed)
                self.startButton.isEnabled = true
                self.selectFileButton.isEnabled = true
                self.startButton.setTitle("Reprocess", for: .normal)
                self.startButton.backgroundColor = .systemGreen

                // Stop accessing security-scoped resource
                self.selectedFileURL?.stopAccessingSecurityScopedResource()

                // Show completion alert
                if let currentProjectPath = self.currentProjectPath {
                    let folderName = (currentProjectPath as NSString).lastPathComponent
                    self.showAlert(
                        title: "Processing Completed",
                        message: "Audio separation finished in \(elapsed) seconds.\nResults saved in project folder: \(folderName)")
                }
            } else {
                self.statusLabel.text = "Processing failed"
                self.timeLabel.text = ""
                self.startButton.isEnabled = true
                self.selectFileButton.isEnabled = true
                self.startButton.setTitle("Start Processing", for: .normal)
                self.startButton.backgroundColor = .systemGreen

                // Stop accessing security-scoped resource
                self.selectedFileURL?.stopAccessingSecurityScopedResource()

                // Clear project path
                self.currentProjectPath = nil

                // Show error alert
                self.showAlert(title: "Processing Failed", message: error?.localizedDescription ?? "Failed")
            }
        }

    }
}

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            selectedFileURL = url

            // Start accessing security-scoped resource
            _ = selectedFileURL?.startAccessingSecurityScopedResource()

            // Update UI to show file name
            let fileName = selectedFileURL!.lastPathComponent
            fileNameLabel.text = "Selected: \(fileName)"
            fileNameLabel.textColor = .label

            // Update button state
            updateUIState()

            print("Selected file: \(selectedFileURL!.path)")
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }
}
