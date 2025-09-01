//
//  ProjectView.swift
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/27.
//

import SwiftUI

struct ProjectView: View {
    @State private var projectFolders: [ProjectFolder] = []
    @State private var isLoading = true
    @State private var showDeleteAlert = false
    @State private var folderToDelete: ProjectFolder?

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading projects...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if projectFolders.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "waveform")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No projects yet")
                            .font(.title2)
                            .foregroundColor(.secondary)

                        Text("Projects will appear here after processing files on the Audio Processing tab")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(projectFolders) { folder in
                            NavigationLink(destination: ProjectDetailView(projectFolder: folder)
                                .toolbar(.hidden, for: .tabBar)) {
                                    ProjectFolderRow(folder: folder)
                                }
                        }
                        .onDelete(perform: deleteProject)
                    }
                    .confirmationDialog("Delete Project", isPresented: $showDeleteAlert, titleVisibility: .visible) {
                        Button("Delete", role: .destructive) {
                            if let folder = folderToDelete {
                                performDelete(folder: folder)
                            }
                        }
                        Button("Cancel", role: .cancel) {
                            folderToDelete = nil
                        }
                    } message: {
                        Text("This action cannot be undone. The project and all its files will be permanently deleted.")
                    }
                    .refreshable {
                        await loadProjectFolders()
                    }
                }
            }
            .navigationTitle("Projects")
            .onAppear {
                Task {
                    await loadProjectFolders()
                }
            }
        }
    }

    @MainActor
    private func loadProjectFolders() async {
        isLoading = true

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: documentsPath,
                includingPropertiesForKeys: [.creationDateKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            var folders: [ProjectFolder] = []

            for url in contents {
                let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .creationDateKey])

                if resourceValues.isDirectory == true && url.lastPathComponent.hasSuffix(".stemifyproj") {
                    let name = url.deletingPathExtension().lastPathComponent
                    let folder = ProjectFolder(
                        name: name,
                        path: url.path,
                        creationDate: resourceValues.creationDate ?? Date(),
                        fileCount: countFilesInFolder(url)
                    )
                    folders.append(folder)
                }
            }

            // Sort by creation date in descending order
            projectFolders = folders.sorted { $0.creationDate > $1.creationDate }
        } catch {
            print("Failed to load project folders: \(error)")
            projectFolders = []
        }

        isLoading = false
    }

    private func countFilesInFolder(_ url: URL) -> Int {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            return contents.count
        } catch {
            return 0
        }
    }

    private func deleteProject(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        folderToDelete = projectFolders[index]
        showDeleteAlert = true
    }

    private func performDelete(folder: ProjectFolder) {
        do {
            let folderURL = URL(fileURLWithPath: folder.path)
            try FileManager.default.removeItem(at: folderURL)

            // Remove from array
            if let index = projectFolders.firstIndex(where: { $0.id == folder.id }) {
                projectFolders.remove(at: index)
            }

            print("Successfully deleted project: \(folder.name)")
        } catch {
            print("Failed to delete project folder: \(error.localizedDescription)")
        }

        folderToDelete = nil
    }

    // Removed openFolder function as navigation is now handled by NavigationLink
}



struct ProjectView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectView()
    }
}
