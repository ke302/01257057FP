//
//  StoryOption.swift
//  01257057FP
//
//  Created by user05 on 2025/12/18.
//
import Foundation
import FoundationModels

// 用來讓 GameManager 跟 UI 溝通的橋樑 (保持不變)
@Observable
class GameStateBridge {
    @MainActor static let shared = GameStateBridge()
    var currentOptions: [String] = []
}

// Plan B 的核心：定義 AI 必須產生的資料結構
@Generable
struct StoryTurn {
    // 1. 故事內容
    @Guide(description: "當前的劇情發展，約 300~500 字，生動且具臨場感。純文字，不要包含任何程式碼或 JSON 符號。不要包含「選擇：」或任何選項列表。")
    var story: String
    
    // 2. 選項
    @Guide(description: "提供給玩家的 2~3 個行動選項，簡短有力。不要包含 'json' 或格式說明。")
    var options: [String]
}

