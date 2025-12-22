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
    @AppStorage("speechRate") private var storedSpeechRate: Double = 0.5
    @AppStorage("speechVolume") private var storedSpeechVolume: Double = 1.0
    @AppStorage("bgmVolume") private var storedBGMVolume: Double = 0.3
    
    var body: some View {
        NavigationStack {
            Form {
                Section("聲音設定") {
                    // 1. BGM 開關
                    Toggle(isOn: $isBGMEnabled) {
                        HStack {
                            Image(systemName: isBGMEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .foregroundStyle(themeColor)
                            Text("背景音樂 (BGM)")
                        }
                    }
                    .onChange(of: isBGMEnabled) {
                        gameManager.isBGMEnabled = isBGMEnabled
                        if !isBGMEnabled {
                            gameManager.stopBGM()
                        }
                    }
                    if isBGMEnabled {
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "speaker.wave.1.fill").font(.caption)
                                Text("音樂音量: \(Int(storedBGMVolume * 100))%")
                                Spacer()
                                Image(systemName: "speaker.wave.3.fill").font(.caption)
                            }
                            .foregroundStyle(themeColor)
                            
                            Slider(value: $storedBGMVolume, in: 0.0...1.0, step: 0.1)
                                .onChange(of: storedBGMVolume) {
                                    // 同步更新到 Manager
                                    gameManager.bgmVolume = Float(storedBGMVolume)
                                }
                        }
                    }
                    Divider().padding(.vertical, 5)
                    // 2. 語速調整
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "tortoise.fill").font(.caption)
                            Text("說話語速: \(String(format: "%.1f", storedSpeechRate))")
                            Spacer()
                            Image(systemName: "hare.fill").font(.caption)
                        }
                        .foregroundStyle(themeColor)
                        
                        Slider(value: $storedSpeechRate, in: 0.1...0.9, step: 0.1)
                            .onChange(of: storedSpeechRate) {
                                gameManager.speechRate = Float(storedSpeechRate)
                            }
                    }
                    
                    // 3. 音量調整
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "speaker.fill").font(.caption)
                            Text("朗讀音量: \(Int(storedSpeechVolume * 100))%")
                            Spacer()
                            Image(systemName: "speaker.wave.3.fill").font(.caption)
                        }
                        .foregroundStyle(themeColor)
                        
                        Slider(value: $storedSpeechVolume, in: 0.0...1.0, step: 0.1)
                            .onChange(of: storedSpeechVolume) {
                                gameManager.speechVolume = Float(storedSpeechVolume)
                            }
                    }
                }
                
                Section("外觀設定") {
                    ColorPicker("介面主題色", selection: $themeColor)
                }
                
                Section {
                    Text("流浪者酒館 v1.1")
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
                gameManager.isBGMEnabled = isBGMEnabled
                gameManager.bgmVolume = Float(storedBGMVolume)
                gameManager.speechRate = Float(storedSpeechRate)
                gameManager.speechVolume = Float(storedSpeechVolume)
            }
        }
    }
}
