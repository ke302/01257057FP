//
//  Character.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//
import SwiftUI

struct CharacterCreationView: View {
    @Binding var isGameStarted: Bool
    @State private var playerName = ""
    @State private var selectedClass = "戰士"
    @State private var strength = 10
    @State private var agility = 10
    @State private var isHardMode = false
    
    let classes = ["戰士", "法師", "盜賊", "弓箭手"]
    
    var body: some View {
        Form {
            Section("冒險者註冊") {
                // 1. TextField
                TextField("請輸入名字", text: $playerName)
                
                // 2. Picker
                Picker("選擇職業", selection: $selectedClass) {
                    ForEach(classes, id: \.self) { role in
                        Text(role)
                    }
                }
            }
            
            Section("能力值分配") {
                // 3. Stepper
                Stepper("力量: \(strength)", value: $strength, in: 1...20)
                Stepper("敏捷: \(agility)", value: $agility, in: 1...20)
            }
            
            Section("遊戲設定") {
                // 4. Toggle
                Toggle("開啟困難模式 (怪物 HP 兩倍)", isOn: $isHardMode)
            }
            
            Button("開始冒險") {
                // 這裡可以把資料傳給 Manager
                isGameStarted = true
            }
            .disabled(playerName.isEmpty)
        }
    }
}
