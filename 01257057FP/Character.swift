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
                // [1] 設定角色名稱
                Section(header: Text("角色名稱")) {
                    TextField("輸入名稱", text: $gameManager.charName)
    
                    Text("\(gameManager.charName.count)/15")
                        .font(.caption)
                        .foregroundStyle(gameManager.charName.count == 15 ? .red : .secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                // [2] 設定角色圖片關鍵字 (150字, 5次機會)
                Section(header: Text("角色圖片關鍵字")) {
                    TextEditor(text: $gameManager.imagePrompt)
                        .frame(height: 80)
                    
                    HStack {
                        Text("剩餘次數: \(gameManager.imageRetryCount)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Spacer()
                        Text("\(gameManager.imagePrompt.count)/150")
                            .font(.caption)
                            .foregroundStyle(gameManager.imagePrompt.count == 150 ? .red : .secondary)
                    }
                    
                    // 預覽按鈕
                    Button("生成") {
                        Task {
                            await gameManager.fetchPlayerImage()
                        }
                    }
                    .disabled(gameManager.imagePrompt.isEmpty)
                    
                    if let url = gameManager.playerImageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    Color.gray.opacity(0.2)
                                    ProgressView()
                                }
                            case .success(let image):
                                image.resizable().scaledToFit()
                            case .failure:
                                ZStack {
                                    Color.gray.opacity(0.2)
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundStyle(.gray)
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(height: 150)
                        .cornerRadius(10)
                    }
                }
                
                // [4] 角色設定 (150字)
                Section(header: Text("角色設定")) {
                    TextEditor(text: $gameManager.charSettings)
                        .frame(height: 100)
                        .overlay(alignment: .topLeading) {
                            if gameManager.charSettings.isEmpty {
                                Text("例如: 銀髮美少女, 吸血鬼, 惡魔...")
                                    .foregroundStyle(.gray.opacity(0.5))
                                    .padding(8)
                                    .allowsHitTesting(false)
                            }
                        }
                    CharacterCountView(current: gameManager.charSettings.count, limit: 150)
                }
                
                // [5] 弱點 (150字)
                Section(header: Text("弱點")) {
                    TextEditor(text: $gameManager.charWeakness)
                        .frame(height: 80)
                        .overlay(alignment: .topLeading) {
                            if gameManager.charWeakness.isEmpty {
                                Text("例如: 碰到水會融化掉")
                                    .foregroundStyle(.gray.opacity(0.5))
                                    .padding(8)
                                    .allowsHitTesting(false)
                            }
                        }
                    CharacterCountView(current: gameManager.charWeakness.count, limit: 150)
                }
                
                // [6] 技能 (150字)
                Section(header: Text("技能")) {
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
