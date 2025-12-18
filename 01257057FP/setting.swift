//
//  setting.swift
//  01257057FP
//
//  Created by user05 on 2025/12/18.
//
import SwiftUI

struct SettingsView: View {
    // 讓這個 View 可以關閉自己
    @Environment(\.dismiss) var dismiss
    
    // 接收 GameManager 來修改設定
    @Bindable var gameManager: StoryGameManager
    
    // [需求] ColorPicker: 自訂主題色
    @Binding var themeColor: Color
    
    // [需求] Toggle: 是否開啟背景音樂 (假裝的功能)
    @AppStorage("isBGMEnabled") private var isBGMEnabled = true
    
    // [需求] Slider: 文字大小
    @AppStorage("textSize") private var textSize: Double = 16.0
    
    // [需求] DatePicker: 設定角色的生日
    @State private var birthDate = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("角色設定") {
                    // [需求] TextField
                    TextField("主角名字", text: $gameManager.playerName)
                    
                    // [需求] Picker
                    Picker("劇本風格", selection: $gameManager.genre) {
                        Text("賽博龐克").tag("賽博龐克偵探")
                        Text("中世紀奇幻").tag("中世紀奇幻")
                        Text("克蘇魯神話").tag("克蘇魯神話")
                    }
                    
                    // [需求] DatePicker
                    DatePicker("角色生日", selection: $birthDate, displayedComponents: .date)
                }
                
                Section("介面外觀") {
                    // [需求] ColorPicker
                    ColorPicker("主題顏色", selection: $themeColor)
                    
                    // [需求] Slider
                    VStack(alignment: .leading) {
                        Text("文字大小: \(Int(textSize))")
                        Slider(value: $textSize, in: 14...24, step: 1)
                    }
                }
                
                Section("系統") {
                    // [需求] Toggle
                    Toggle("背景音樂", isOn: $isBGMEnabled)
                }
            }
            .navigationTitle("遊戲設定")
            .toolbar {
                Button("完成") {
                    dismiss()
                }
            }
        }
    }
}
