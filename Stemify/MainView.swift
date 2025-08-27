//
//  MainView.swift
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/27.
//

import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @StateObject private var viewModel = StemifyViewModel()
    @State private var showingFileImporter = false

    var body: some View {
        VStack(spacing: 20) {
            // File name label
            Text(viewModel.fileName)
                .font(.system(size: 16))
                .foregroundColor(viewModel.isStartButtonEnabled ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 20)

            // Select file button
            Button(action: { showingFileImporter = true }) {
                Text("Select Audio File")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 200, height: 44)
            }
            .disabled(viewModel.isProcessing)

            // Model selection menu
            Menu {
                ForEach(Spleeter.Model.all, id: \.rawValue) {
                    model in
                    Button(action: { viewModel.selectedModel = model }) {
                        HStack {
                            Text(model.name)
                            if viewModel.selectedModel == model {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text("Model: ")
                        .foregroundStyle(Color.primary)
                    if #available(iOS 26.0, *) {
                        HStack {
                            Text(viewModel.selectedModel.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                        .glassEffect()
                        .clipShape(.capsule)
                    } else {
                        HStack {
                            Text(viewModel.selectedModel.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    }
                }
            }
            .disabled(viewModel.isProcessing)

            // Start button
            Button(action: { viewModel.processAudio() }) {
                Text(viewModel.isProcessing ? "Processing..." : viewModel.isStartButtonEnabled ? "Reprocess" : "Start Processing")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(viewModel.isStartButtonEnabled ? Color.green : Color.gray)
                    .cornerRadius(8)
            }
            .disabled(!viewModel.isStartButtonEnabled)

            // Status label
            Text(viewModel.status)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Progress bar
            ProgressView(value: viewModel.progress, total: 1.0)
                .progressViewStyle(.linear)
                .tint(.blue)
                .frame(height: 4)
                .padding(.horizontal, 40)

            // Time label
            Text(viewModel.timeInfo)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.top, 40)
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.selectFile(url: url)
                }
            case .failure(let error):
                viewModel.alertTitle = "Error"
                viewModel.alertMessage = "Unable to select file: \(error.localizedDescription)"
                viewModel.showAlert = true
            }
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

extension Spleeter.Model {
    var name: String {
        switch self {
        case .model2Stems:
            return "2 Stems"
        case .model5Stems:
            return "5 Stems"
        @unknown default:
            fatalError()
        }
    }
    static var all: [Self] {
        [.model2Stems, .model5Stems]
    }
}

struct SpleeterView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
