//
//  SpleeterModelExtension.swift
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/27.
//

import Foundation

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
