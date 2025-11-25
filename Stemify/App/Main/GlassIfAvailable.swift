//
//  GlassIfAvailable.swift
//  Stemify
//
//  Created by XueyuanXiao on 11/25/25.
//

import SwiftUI

struct GlassIfAvailable: ViewModifier {
    var isProminent = true

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if isProminent {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.glass)
            }
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

extension View {
    @ViewBuilder
    func glassIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect()
        } else {
            self.background(.ultraThinMaterial)
        }
    }
}
