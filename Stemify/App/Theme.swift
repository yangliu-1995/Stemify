//
//  Theme.swift
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/27.
//

import SwiftUI

// MARK: - Card Corner Radius Environment Key
struct CardCornerRadiusKey: EnvironmentKey {
    static let defaultValue: CGFloat = {
        if #available(iOS 26.0, *) {
            return 24
        } else {
            return 12
        }
    }()
}

extension EnvironmentValues {
    var cardCornerRadius: CGFloat {
        get { self[CardCornerRadiusKey.self] }
        set { self[CardCornerRadiusKey.self] = newValue }
    }
}