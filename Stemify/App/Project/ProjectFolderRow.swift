//
//  ProjectFolderRow.swift
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/27.
//

import SwiftUI

struct ProjectFolderRow: View {
    let folder: ProjectFolder
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: folder.creationDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(folder.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("\(folder.fileCount) tracks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProjectFolderRow_Previews: PreviewProvider {
    static var previews: some View {
        ProjectFolderRow(
            folder: ProjectFolder(
                name: "SpleeterProject_20240127_143052",
                path: "/Documents/SpleeterProject_20240127_143052",
                creationDate: Date(),
                fileCount: 3
            )
        )
        .padding()
    }
}
