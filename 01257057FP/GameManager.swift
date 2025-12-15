//
//  main.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//
import Foundation
import SwiftUI
import FoundationModels

@Observable
class DungeonGameManager {
    var session: LanguageModelSession
    var storyText: String = ""
    var isVictory: Bool = false
    
    // --- 新增角色設定 ---
    var charName: String = ""
    var imagePrompt: String = ""
    var charSettings: String = ""
    var charWeakness: String = ""
    var charSkills: String = ""
    var charSummary: String = "" // 自動生成的概述
    
    // --- 世界與故事設定 ---
    var worldSetting: String = "" // 例如: 賽博龐克、修仙世界
    var storyGoal: String = ""    // 例如: 尋找失落的聖劍、向魔王復仇
    
    // --- 結局與評價 ---
    var isGameOver: Bool = false
    var evaluationReport: String = "" // 最終評價內容
    var showEvaluation: Bool = false  // 控制彈窗顯示
    
    // --- 圖片生成相關 ---
    var currentBackgroundImageURL: URL?
    var currentEnemyImageURL: URL?
    var playerImageURL: URL? // 玩家自訂圖
    let imageFetcher = ImageFetcher()
    var imageRetryCount: Int = 5 // 5次機會
    
    // 戰鬥狀態 (保留部分，但主要依賴 AI 敘事)
    var currentEnemyHP: Int = 0
    var playerHP: Int = 100
    var healCooldown: Int = 0
    
    init() {
        // 初始 Session 先給一個基底，稍後 startAdventure 會重設
        let diceTool = DiceRollTool()
        self.session = LanguageModelSession(tools: [diceTool])
    }
    
    // --- [重要] 遊戲開始時，把逆天設定餵給 AI ---
    func startAdventure() async {
        let diceTool = DiceRollTool()
        
        let instructions = """
        你是一個 TRPG 的地下城主 (DM)。
        
        【玩家角色資料】
        - 名字: \(charName)
        - 外觀與設定: \(charSettings)
        - 弱點: \(charWeakness)
        - 技能: \(charSkills)
        
        【世界觀與目標】
                - 世界背景: \(worldSetting)
                - 故事目標: \(storyGoal)
        
        【遊戲規則】
                1. 遊戲開始時，請根據世界觀描述周圍環境，並說明角色的現狀。
                2. 之後每次玩家輸入行動，請判斷結果並推進劇情。
                3. 遇到戰鬥或機率事件，**必須**呼叫 'rollDice' tool。
                4. 如果玩家死亡或達成最終目標，請明確告知遊戲結束。
                5. 你的敘述要生動，讓玩家沉浸其中。
        """
        
        self.session = LanguageModelSession(
            tools: [diceTool],
            instructions: instructions
        )
        
        // 抓取玩家圖片 (使用 imagePrompt)
        // 抓取玩家圖片
        await fetchPlayerImage()
        // 抓取背景圖 (用世界設定當關鍵字)
        await fetchBackgroundImage(query: worldSetting)
        
        // 讓 AI 講開場白
        await performStoryUpdate(prompt: "遊戲開始。請描述世界觀、開場環境以及主角目前的處境。")
    }
    
    // --- 2. 處理玩家輸入 (自由行動) ---
    func processPlayerInput(_ input: String) async {
        // 更新 UI 顯示玩家說的話
        let playerLog = "\n\n🧑‍💻 你: \(input)\n"
        self.storyText += playerLog
        
        // 讓 AI 回應
        await performStoryUpdate(prompt: "玩家行動: \(input)。請判定結果並推進劇情。")
    }
    
    // --- 3. 結束遊戲與評價 ---
    func endGameAndEvaluate() async {
        self.isGameOver = true
        let prompt = "遊戲結束。請撰寫一份「冒險評價報告」，包含：\n1. 角色經歷摘要\n2. 達成的成就\n3. 最終結局\n4. 給予一個評分 (S~F)。"
        
        do {
            let response = try await session.respond(to: prompt, generating: String.self)
            self.evaluationReport = response.content
            self.showEvaluation = true
        } catch {
            self.evaluationReport = "評價生成失敗: \(error)"
            self.showEvaluation = true
        }
    }
    // 輔助: 抓背景圖
    func fetchBackgroundImage(query: String) async {
        if let url = await imageFetcher.fetchImageURL(query: query) {
            self.currentBackgroundImageURL = url
        }
    }
    func fetchPlayerImage() async {
        guard imageRetryCount > 0 else { return }
        // 這裡假設 imageFetcher 支援更精準的 query
        // 實際運作：如果關鍵字被和諧(Unsplash 搜不到)，可以讓使用者在 UI 再試一次
        if let url = await imageFetcher.fetchImageURL(query: imagePrompt) {
            self.playerImageURL = url
        } else {
            // 失敗不扣機會 (根據你的需求)，或者你要扣也可以
            // imageRetryCount -= 1
            print("圖片生成/抓取失敗")
        }
    }
    func generateAutoSummary() async {
        let prompt = "請根據以下設定，用一句話帥氣地介紹這位角色：\n名字:\(charName)\n設定:\(charSettings)\n弱點:\(charWeakness)\n技能:\(charSkills)"
        do {
            // 修正 1: 明確指定 generating 為 String.self (雖然有些版本可省略，但這樣寫最保險)
            // 修正 2: 使用 .content 取得文字
            let response = try await session.respond(to: prompt, generating: String.self)
            
            // 必須在 Main Actor (主執行緒) 更新 UI 變數，或者因為 Class 有 @Observable 且在 async context，SwiftUI 通常能處理，但最標準是用 .content
            self.charSummary = response.content
        } catch {
            print("概述生成失敗: \(error)")
            self.charSummary = "（無法生成概述，請檢查網路或模型狀態）"
        }
    }
    // 輔助: 串流更新故事
    private func performStoryUpdate(prompt: String) async {
        let baseHistory = self.storyText
        
        // 2. 準備分隔線 (如果原本有字，就加換行)
        let separator = baseHistory.isEmpty ? "" : "\n\n"
        
        let stream = session.streamResponse(to: prompt)
        
        do {
            for try await partial in stream {
                // 3. 組合：舊歷史 + 分隔線 + AI目前講的話
                // [重要] 這裡是使用 `=` (賦值)，絕對不能用 `+=` (累加)
                // partial.content 包含了 AI 這次回應的「完整片段」，所以我們直接接在歷史後面就好
                self.storyText = baseHistory + separator + partial.content
            }
        } catch {
            print("劇情生成錯誤: \(error)")
        }
    }
}

