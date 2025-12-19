//
//  setting.swift
//  01257057FP
//
//  Created by user05 on 2025/12/18.
//
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // 連結 StoryManager (為了控制 BGM)
    @Bindable var gameManager: StoryManager
    
    // 連結主題色 (為了控制 App 外觀)
    @Binding var themeColor: Color
    
    // 使用 AppStorage 記住設定
    @AppStorage("isBGMEnabled") private var isBGMEnabled = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("系統設定") {
                    // [需求] Toggle: BGM 開關
                    Toggle(isOn: $isBGMEnabled) {
                        HStack {
                            Image(systemName: isBGMEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .foregroundStyle(themeColor)
                            Text("背景音樂 (BGM)")
                        }
                    }
                    .onChange(of: isBGMEnabled) {
                        gameManager.isBGMEnabled = isBGMEnabled
                    }
                    
                    // [需求] ColorPicker: 讓玩家選喜歡的 App 主題色
                    ColorPicker("介面主題色", selection: $themeColor)
                }
                
                Section {
                    Text("流浪者酒館 v1.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("完成") { dismiss() }
            }
            .onAppear {
                // 同步狀態
                gameManager.isBGMEnabled = isBGMEnabled
            }
        }
    }
}
