//
//  SettingsView.swift
//  Scribe
//
//  Created by Scribe Team on 2024.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            AISettingsView()
                .tabItem {
                    Label("AI 设置", systemImage: "brain")
                }
            
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("通用设置")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("应用信息")
                    .font(.headline)
                
                HStack {
                    Text("版本:")
                        .foregroundColor(.secondary)
                    Text("1.0.0")
                }
                
                HStack {
                    Text("构建:")
                        .foregroundColor(.secondary)
                    Text("2024.1")
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}