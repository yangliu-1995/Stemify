//
//  SettingView.swift
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/27.
//

import SwiftUI

enum OutputFormat: String, CaseIterable {
    case mp3 = "mp3"
    case aac = "aac"
    case m4a = "m4a"
    case wav = "wav"
    
    var displayName: String {
        return rawValue.uppercased()
    }
}

struct SettingView: View {
    @AppStorage("outputFormat") private var selectedOutputFormat: OutputFormat = .mp3
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "gear")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Output Format Setting
                VStack(spacing: 16) {
                    HStack {
                        Text("Output Format:")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(OutputFormat.allCases, id: \.self) { format in
                                Button(action: { selectedOutputFormat = format }) {
                                    HStack {
                                        Text(format.displayName)
                                        if selectedOutputFormat == format {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedOutputFormat.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
