//
//  main.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//
// GameManager.swift
import Foundation
import SwiftUI
import FoundationModels

@Observable
class StoryGameManager {
    var session: LanguageModelSession
    var displayedStory: String = "" // 畫面上的故事文字
    var isGenerating: Bool = false
    var errorMessage: String?
    
    // 遊戲設定 (Binding 用)
    var genre: String = "賽博龐克偵探"
    var playerName: String = "V"
    
    init() {
        // 依照 PDF 第 52 頁，初始化時把 Tool 塞進去
        let tool = StoryOptionTool()
        self.session = LanguageModelSession(tools: [tool])
    }
    
    // [效能優化] PDF 第 61 頁：Prewarm
    func warmUp() {
        Task {
            await session.prewarm()
        }
    }
    
    // 開始新遊戲
    func startStory() async {
        resetGame()
        
        // 設定 AI 的人設 (Instructions)
        let instructions = """
        你是一個互動小說的導演。
        當前的劇本類型：\(genre)。
        主角名字：\(playerName)。
        
        【規則】
        1. 每次只產生約 100~200 字的劇情，然後停止。
        2. 劇情結束時，**務必**呼叫 'presentOptions' 工具，提供 2~3 個選項。
        3. 不要自己輸出選項清單 (例如 A. xxx)，直接用 Tool。
        """
        
        // 重新初始化 Session (PDF 第 360 頁建議：每次新對話建立新 Session)
        self.session = LanguageModelSession(
            tools: [StoryOptionTool()],
            instructions: instructions
        )
        
        await sendPrompt("遊戲開始，請描述開場。")
    }
    
    // 玩家點擊按鈕後
    func playerSelected(_ choice: String) async {
        // 清空選項，避免重複點擊
        await MainActor.run {
            GameStateBridge.shared.currentOptions = []
            // 把玩家的選擇加到畫面上，增加帶入感
            self.displayedStory += "\n\n👉 [\(choice)]\n\n"
        }
        
        // 把選擇傳給 AI (PDF 第 14 頁：Session 會記得之前的內容)
        await sendPrompt("玩家選擇了：\(choice)。請繼續劇情。")
    }
    
    private func resetGame() {
        displayedStory = ""
        GameStateBridge.shared.currentOptions = []
        isGenerating = false
    }
    
    // 核心：串流請求 (PDF 第 39-41 頁)
    private func sendPrompt(_ text: String) async {
        guard !isGenerating else { return }
        isGenerating = true
        
        do {
            let stream = session.streamResponse(to: text)
            
            for try await partial in stream {
                // 將 AI 吐出的文字即時更新到畫面
                if !partial.content.isEmpty {
                    await MainActor.run {
                        self.displayedStory = partial.content
                    }
                }
            }
        } catch {
            print("AI Error: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isGenerating = false
    }
}

