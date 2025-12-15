//
//  WorldSetting.swift
//  01257057FP
//
//  Created by user05 on 2025/12/15.
//
import SwiftUI

struct WorldSettingView: View {
    @Bindable var gameManager: DungeonGameManager
    @Binding var gameState: GameState // 用來控制流程
    
    var body: some View {
        Form {
            Section(header: Text("世界觀設定")) {
                TextField("例如:充滿霓虹燈的賽博龐克都市", text: $gameManager.worldSetting)
                // 也可以加一個隨機按鈕讓 AI 幫忙想
            }
            
            Section(header: Text("故事目標")) {
                TextField("例如: 尋找失散多年的妹妹", text: $gameManager.storyGoal)
            }
            
            Section {
                Button("開始冒險") {
                    // 1. 切換狀態到遊戲中
                    gameState = .playing
                    // 2. 觸發 AI 初始化
                    Task {
                        await gameManager.startAdventure()
                    }
                }
                .disabled(gameManager.worldSetting.isEmpty)
            }
        }
        .navigationTitle("冒險舞台設定")
    }
}
