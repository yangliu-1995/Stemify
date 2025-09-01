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
    @Environment(\.cardCornerRadius) private var cardCornerRadius

    private var fileButtonShape: AnyShape {
        if #available(iOS 26.0, *) {
            AnyShape(Capsule())
        } else {
            AnyShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var modelButtonShape: AnyShape {
        if #available(iOS 26.0, *) {
            AnyShape(Capsule())
        } else {
            AnyShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // File selection card
                    VStack(spacing: 16) {
                        Text(viewModel.fileName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

                        Button(action: { showingFileImporter = true }) {
                            HStack {
                                Image(systemName: "folder")
                                Text("Select Audio File")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(viewModel.isProcessing ? .secondary : Color(.label))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(viewModel.isProcessing ? Color.gray.opacity(0.1) : Color(.label).opacity(0.1))
                            .clipShape(fileButtonShape)
                        }
                        .disabled(viewModel.isProcessing)
                        .opacity(viewModel.isProcessing ? 0.6 : 1.0)
                    }
                    .padding(20)
                    .background(Color(.systemGray6))
                    .cornerRadius(cardCornerRadius)
                    .padding(.horizontal, 20)

                    // Processing controls card
                    VStack(spacing: 16) {
                        // Model selection
                        HStack {
                            Text("Model:")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)

                            Spacer()

                            Menu {
                                ForEach(Spleeter.Model.all, id: \.rawValue) { model in
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
                                    Text(viewModel.selectedModel.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(viewModel.isProcessing ? .secondary : .primary)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(viewModel.isProcessing ? Color(.systemGray4) : Color(.systemGray5))
                                .clipShape(modelButtonShape)
                            }
                            .disabled(viewModel.isProcessing)
                            .opacity(viewModel.isProcessing ? 0.6 : 1.0)
                        }

                        // Processing button or progress
                        ProcessingButton(
                            isProcessing: viewModel.isProcessing,
                            progress: viewModel.progress,
                            isEnabled: viewModel.isStartButtonEnabled,
                            action: { viewModel.processAudio() }
                        )

                        // Status text
                        Text(viewModel.status)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(Color(.systemGray6))
                    .cornerRadius(cardCornerRadius)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 50)
                }
                .frame(maxWidth: 500)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
            }
            .navigationTitle("Audio Processor")
            .navigationBarTitleDisplayMode(.large)
        }
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

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
