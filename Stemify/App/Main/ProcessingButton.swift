//
//  ProcessingButton.swift
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/27.
//

import SwiftUI

struct ProcessingButton: View {
    let isProcessing: Bool
    let progress: Float
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        GeometryReader { proxy in
            Button(action: action) {
                ZStack {
                    // Background
                    Group {
                        if #available(iOS 26.0, *) {
                            Capsule()
                                .fill(buttonBackgroundColor)
                                .glassEffect()
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(buttonBackgroundColor)
                        }
                    }
                    .frame(height: 50)

                    if isProcessing {
                        // Progress background
                        HStack {
                            Rectangle()
                                .fill(Color(.label))
                                .frame(width: proxy.size.width * CGFloat(progress))
                            Spacer(minLength: 0)
                        }
                        .frame(height: 50)

                        // Progress text
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(.systemBackground)))
                                .scaleEffect(0.8)
                            Text(String(format: "%.0f%%", progress * 100))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(.systemBackground))
                        }
                    } else {
                        // Normal button content
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text(buttonText)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                    }
                }
                .clipShape(buttonShape)
            }
            .frame(height: 50)
            .disabled(!isEnabled && !isProcessing)
            .animation(.easeInOut(duration: 0.3), value: isProcessing)
        }
    }
    
    private var buttonBackgroundColor: Color {
        if isProcessing {
            return Color(.label).opacity(0.6)
        } else if isEnabled {
            return Color(.label)
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var buttonText: String {
        if isEnabled {
            return "Start Processing"
        } else {
            return "Start Processing"
        }
    }
    
    private var buttonShape: AnyShape {
        if #available(iOS 26.0, *) {
            AnyShape(Capsule())
        } else {
            AnyShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct ProcessingButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProcessingButton(
                isProcessing: false,
                progress: 0.0,
                isEnabled: true,
                action: {}
            )
            
            ProcessingButton(
                isProcessing: true,
                progress: 0.65,
                isEnabled: false,
                action: {}
            )
        }
        .padding()
    }
}
