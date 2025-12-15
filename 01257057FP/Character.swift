//
//  Character.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//
import SwiftUI

struct CharacterCreationView: View {
    @Binding var gameState: GameState
    @Bindable var gameManager: DungeonGameManager
    
    var body: some View {
        NavigationStack {
            Form {
                // [1] 設定角色名稱 (15字)
                Section(header: Text("角色名稱 (上限15字)")) {
                    TextField("輸入名稱 (例如: 麥當勞叔叔)", text: $gameManager.charName)
                        .onChange(of: gameManager.charName) { _, newValue in
                            if newValue.count > 15 {
                                gameManager.charName = String(newValue.prefix(15))
                            }
                        }
                    Text("\(gameManager.charName.count)/15")
                        .font(.caption)
                        .foregroundStyle(gameManager.charName.count == 15 ? .red : .secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                // [2] 設定角色圖片關鍵字 (150字, 5次機會)
                Section(header: Text("角色圖片關鍵字 (AI產圖)")) {
                    TextEditor(text: $gameManager.imagePrompt)
                        .frame(height: 80)
                        .onChange(of: gameManager.imagePrompt) { _, newValue in
                            if newValue.count > 150 {
                                gameManager.imagePrompt = String(newValue.prefix(150))
                            }
                        }
                    
                    HStack {
                        Text("剩餘嘗試次數: \(gameManager.imageRetryCount)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Spacer()
                        Text("\(gameManager.imagePrompt.count)/150")
                            .font(.caption)
                            .foregroundStyle(gameManager.imagePrompt.count == 150 ? .red : .secondary)
                    }
                    
                    // 預覽按鈕
                    Button("試算圖片 (不扣次數)") {
                        Task {
                            await gameManager.fetchPlayerImage()
                        }
                    }
                    .disabled(gameManager.imagePrompt.isEmpty)
                    
                    if let url = gameManager.playerImageURL {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 150)
                        .cornerRadius(10)
                    }
                }
                
                // [4] 角色設定 (150字)
                Section(header: Text("角色設定 (各種逆天設定)")) {
                    TextEditor(text: $gameManager.charSettings)
                        .frame(height: 100)
                        .overlay(alignment: .topLeading) {
                            if gameManager.charSettings.isEmpty {
                                Text("例如: 銀髮美少女, 吸血鬼, 語尾DesuWa...")
                                    .foregroundStyle(.gray.opacity(0.5))
                                    .padding(8)
                                    .allowsHitTesting(false)
                            }
                        }
                        .onChange(of: gameManager.charSettings) { _, newValue in
                            if newValue.count > 150 { gameManager.charSettings = String(newValue.prefix(150)) }
                        }
                    CharacterCountView(current: gameManager.charSettings.count, limit: 150)
                }
                
                // [5] 弱點 (150字)
                Section(header: Text("弱點 (可鬼扯)")) {
                    TextEditor(text: $gameManager.charWeakness)
                        .frame(height: 80)
                        .overlay(alignment: .topLeading) {
                            if gameManager.charWeakness.isEmpty {
                                Text("例如: 太可愛迷死對手, 從來沒輸過...")
                                    .foregroundStyle(.gray.opacity(0.5))
                                    .padding(8)
                                    .allowsHitTesting(false)
                            }
                        }
                        .onChange(of: gameManager.charWeakness) { _, newValue in
                            if newValue.count > 150 { gameManager.charWeakness = String(newValue.prefix(150)) }
                        }
                    CharacterCountView(current: gameManager.charWeakness.count, limit: 150)
                }
                
                // [6] 技能 (150字)
                Section(header: Text("技能 (越多越好)")) {
                    TextEditor(text: $gameManager.charSkills)
                        .frame(height: 100)
                        .overlay(alignment: .topLeading) {
                            if gameManager.charSkills.isEmpty {
                                Text("*分身:多重分身\n*絕對破壞:一擊必殺")
                                    .foregroundStyle(.gray.opacity(0.5))
                                    .padding(8)
                                    .allowsHitTesting(false)
                            }
                        }
                        .onChange(of: gameManager.charSkills) { _, newValue in
                            if newValue.count > 150 { gameManager.charSkills = String(newValue.prefix(150)) }
                        }
                    CharacterCountView(current: gameManager.charSkills.count, limit: 150)
                }
                
                // [3] 自動生成概述與開始
                Section {
                    Button("自動生成角色概述") {
                        Task { await gameManager.generateAutoSummary() }
                    }
                    // 顯示生成結果
                    if !gameManager.charSummary.isEmpty {
                        Text(gameManager.charSummary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 5)
                    }
                    // 修改這裡：前往下一步
                    Button("下一步：世界設定") {
                        gameState = .settingWorld // 切換到設定頁面
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(gameManager.charName.isEmpty ? Color.gray : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                    .disabled(gameManager.charName.isEmpty)
                }
            }
            .navigationTitle("自創角色")
            
            
        }
    }
}

// 輔助用的字數顯示 View
struct CharacterCountView: View {
    let current: Int
    let limit: Int
    
    var body: some View {
        Text("\(current)/\(limit)")
            .font(.caption)
            .foregroundStyle(current == limit ? .red : .secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
