//
//  ProjectFolder.swift
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/27.
//

import Foundation

struct ProjectFolder: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let creationDate: Date
    let fileCount: Int
}
