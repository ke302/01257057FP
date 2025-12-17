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
    
    // --- 記憶管理 ---
    var storySummary: String = "遊戲剛開始。" // 長期記憶摘要
    var summarizedCount: Int = 0           // 記錄 storyText 中已經被摘要過的字數
    var suggestedActions: [String] = []
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
    
    // 狀態鎖定與錯誤處理
    var isGenerating: Bool = false // 用來鎖定 UI
    var errorMessage: String = ""  // 錯誤訊息
    var showError: Bool = false    // 控制錯誤彈窗
    
    init() {
        let diceTool = DiceRollTool()
        self.session = LanguageModelSession(tools: [diceTool])
    }
    
    // --- 遊戲開始時 ---
    func startAdventure() async {
        guard !isGenerating else { return }
        isGenerating = true
        
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
        
        【重要規則】
                1. **絕對不要重複已經發生過的劇情**。
                2. **絕對不要重複「遊戲背景」或「開場環境」**，除非玩家回到了起點。
                3. 每次回應**只描述**針對玩家最新行動的結果與後續發展。
                4. 遇到戰鬥或機率事件，必須呼叫 'rollDice' tool。
                5. 敘述要生動，但請直接切入重點。
        """
        
        self.session = LanguageModelSession(
            tools: [diceTool],
            instructions: instructions
        )
        
        // 抓取玩家圖片 (使用 imagePrompt)
        // 抓取玩家圖片
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchPlayerImage() }
            group.addTask { await self.fetchBackgroundImage(query: self.worldSetting) }
        }
        
        // 讓 AI 講開場白
        await performStoryUpdate(prompt: "遊戲開始。請描述世界觀、開場環境以及主角目前的處境。")
        isGenerating = false
    }
    
    // --- 處理玩家輸入 ---
    func processPlayerInput(_ input: String) async {
        guard !isGenerating else { return }
        isGenerating = true
        
        // 1. 清空舊選項 & 更新 UI
        await MainActor.run {
            self.suggestedActions = []
            self.storyText += "\n\n🧑‍💻 你: \(input)\n"
        }
        
        // 2. 抓取最近劇情 (防鬼打牆邏輯)
        let safeLength = 2000
        let recentHistory: String
        if self.storyText.count > safeLength {
            recentHistory = "......(前情提要略)......\n" + String(self.storyText.suffix(safeLength))
        } else {
            recentHistory = self.storyText
        }
        
        // 3. 組合 Prompt (加入按鈕生成指令)
        let promptWithContext = """
            【前情提要】
            \(recentHistory)
            
            【玩家行動】
            \(input)
            
            【系統指令】
            1. 承接劇情，生動描述結果。
            2. **嚴禁重複**上一段的內容。
            3. (重要) 請在回應的最後，提供 3 個建議玩家採取的簡短行動，格式必須嚴格如下：
               [建議：觀察四周]
               [建議：拔劍攻擊]
               [建議：悄悄離開]
            """
        
        await performStoryUpdate(prompt: promptWithContext)
    }
    
    // --- 結束遊戲與評價 ---
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
        isGenerating = false
    }
    // 輔助: 抓背景圖
    func fetchBackgroundImage(query: String) async {
        if let url = await imageFetcher.fetchImageURL(query: query) {
            self.currentBackgroundImageURL = url
        }
    }
    
    func fetchPlayerImage() async {
        guard imageRetryCount > 0 else { return }
        if let url = await imageFetcher.fetchImageURL(query: imagePrompt) {
            self.playerImageURL = url
        } else {
            imageRetryCount -= 1
            print("圖片生成/抓取失敗")
        }
    }
    func generateAutoSummary() async {
        let prompt = "請根據以下設定，用一句話帥氣地介紹這位角色：\n名字:\(charName)\n設定:\(charSettings)\n弱點:\(charWeakness)\n技能:\(charSkills)"
        do {
            
            let response = try await session.respond(to: prompt, generating: String.self)
            
            // 必須在 Main Actor (主執行緒) 更新 UI 變數，或者因為 Class 有 @Observable 且在 async context，SwiftUI 通常能處理，但最標準是用 .content
            self.charSummary = response.content
        } catch {
            print("概述生成失敗: \(error)")
            self.charSummary = "（無法生成概述，請檢查網路或模型狀態）"
        }
        isGenerating = false
    }
    // 輔助: 串流更新故事
    private func performStoryUpdate(prompt: String) async {
        defer { Task { @MainActor in self.isGenerating = false } }
        
        // 暫存完整的 AI 回應，用來解析選項
        var fullResponseBuffer = ""
        
        do {
            let stream = session.streamResponse(to: prompt)
            
            for try await partial in stream {
                let content = partial.content
                fullResponseBuffer += content
                
                await MainActor.run {
                    // 小優化：不要把「[建議：...]」顯示在故事框裡，保持畫面乾淨
                    if !fullResponseBuffer.contains("[建議：") {
                        self.storyText += content
                    }
                }
            }
            
            // 串流結束後，解析選項
            await parseSuggestions(from: fullResponseBuffer)
            
        } catch {
            print("Error: \(error)")
            await MainActor.run {
                self.errorMessage = "連線錯誤，請稍後再試。"
                self.showError = true
            }
        }
    }
    
    // --- 記憶壓縮功能 ---
    func updateStorySummary() async {
        // 定義閾值：如果「還沒被摘要的文字」超過 3000 字，就觸發壓縮
        // 我們保留最後 1000 字作為「短期記憶」，剩下的中間段落拿去壓縮
        let currentLength = storyText.count
        let threshold = 3000
        let buffer = 1000 // 保留給短期記憶的緩衝區
        
        // 只有當累積夠多字時才執行，避免每次行動都跑，浪費錢又浪費時間
        guard (currentLength - summarizedCount) > threshold else { return }
        
        // 1. 抓出需要被壓縮的片段 (從上次摘要的結尾，到最新的緩衝區之前)
        let endIndex = currentLength - buffer
        let textToSummarize = String(storyText.dropFirst(summarizedCount).prefix(endIndex - summarizedCount))
        
        // 2. 準備 Prompt，請 AI 把這段變成摘要
        let summaryPrompt = """
            【目前的劇情摘要】
            \(self.storySummary)
            
            【新發生的劇情片段】
            \(textToSummarize)
            
            【指令】
            請將「目前的劇情摘要」與「新發生的劇情片段」合併，改寫成一份新的、約 300~500 字的「劇情總回顧」。
            重點：
            1. 保留關鍵人名、地名、獲得的道具、達成的承諾。
            2. 去除無意義的對話細節或重複描述。
            3. 以第三人稱敘述。
            """
        
        // 3. 呼叫 AI (這裡可以用原本的 session，或者開一個新的臨時 session 都可以)
        // 為了避免干擾主對話的 context，我們直接用 session.respond
        do {
            print("正在進行記憶壓縮...")
            // 這裡借用 session 來跑摘要
            let response = try await session.respond(to: summaryPrompt, generating: String.self)
            
            // 4. 更新摘要與指標
            self.storySummary = response.content
            self.summarizedCount = endIndex // 更新進度條
            print("記憶壓縮完成！目前摘要長度：\(self.storySummary.count)")
            
        } catch {
            print("記憶壓縮失敗: \(error)")
        }
    }
    func parseSuggestions(from text: String) async {
            // 抓出 [建議：...] 裡面的文字
            let pattern = "\\[建議：(.*?)\\]"
            
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                
                let newActions = results.compactMap { result -> String? in
                    if let range = Range(result.range(at: 1), in: text) {
                        return String(text[range])
                    }
                    return nil
                }
                
                // 更新 UI
                await MainActor.run {
                    self.suggestedActions = newActions
                    // 如果 AI 沒給選項，就給預設值
                    if self.suggestedActions.isEmpty {
                        self.suggestedActions = ["觀察四周", "檢查狀態", "繼續前進"]
                    }
                }
            } catch {
                print("解析選項失敗")
            }
        }
}

