//  GameManager.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//
import Foundation
import SwiftUI
import FoundationModels

@Observable
class StoryGameManager {
    var session: LanguageModelSession
    var displayedStory: String = ""
    var isGenerating: Bool = false
    var errorMessage: String?
    private var previousStoryText: String = ""
    // 遊戲設定
    var genre: String = "賽博龐克偵探"
    var playerName: String = "V"
    
    init() {
        // Plan B: 初始化時不需要塞 Tool 了
        self.session = LanguageModelSession()
    }
    
    func warmUp() {
        Task { await session.prewarm() }
    }
    
    func startStory() async {
        resetGame()
        
        // 設定人設
        let instructions = """
        你是一個互動小說導演，劇本類型：\(genre)。主角：\(playerName)。
                
                【任務】
                1. 根據玩家選擇推進約 300 字的劇情。
                2. 劇情請著重於環境描寫與主角心境。
                3. 最後提供 2~3 個行動選項 (例如：「往左走」、「調查桌子」)。
                4. 請直接輸出故事內容，不要輸出任何 JSON 標籤或程式碼。
                【絕對規則】
                1. **故事內容 (story) 只能包含劇情描述。**
                2. **絕對不要**在故事內容中寫出「選擇：」、「1. xxx 2. xxx」或任何選項清單。
                3. 選項 **必須且只能** 填寫在 `options` 欄位中。
                4. 請直接輸出故事，不要有任何開場白。
        """
        
        // 重新建立 Session，不需 Tool，只需 Instructions
        self.session = LanguageModelSession(instructions: instructions)
        
        // 發送第一句 Prompt
        await sendPrompt("遊戲開始，請描述開場。")
    }
    
    func playerSelected(_ choice: String) async {
        // 鎖定 UI，避免重複點擊
        await MainActor.run {
            // 將玩家的選擇顯示在故事中，增加紀錄感
            self.displayedStory += "\n\n👉 [\(choice)]\n\n"
            // 清空舊選項
            GameStateBridge.shared.currentOptions = []
        }
        
        await sendPrompt("玩家選擇了：\(choice)。請繼續劇情。")
    }
    
    private func resetGame() {
        displayedStory = ""
        GameStateBridge.shared.currentOptions = []
        isGenerating = false
    }
    
    // 核心修改：使用 Structured Output 的串流
    private func sendPrompt(_ text: String) async {
        guard !isGenerating else { return }
        isGenerating = true
        
        // 1. 記錄目前的進度 (包含之前的劇情 + 玩家剛剛做的選擇)
        await MainActor.run {
            self.previousStoryText = self.displayedStory
        }
        
        var pendingOptions: [String] = []
        
        do {
            let stream = session.streamResponse(to: text, generating: StoryTurn.self)
            
            for try await partial in stream {
                await MainActor.run {
                    // 2. 更新故事 (同時過濾掉不小心跑出來的 presentOptions 代碼)
                    if let currentSegment = partial.content.story {
                        // 簡單過濾：如果這段文字包含程式碼特徵，就不要顯示
                        if !currentSegment.contains("presentOptions") && !currentSegment.contains("{\"items\"") {
                            self.displayedStory = self.previousStoryText + currentSegment
                        }
                    }
                    
                    // 3. 暫存選項 (還不要給 Bridge!)
                    if let newOptions = partial.content.options {
                        pendingOptions = newOptions
                    }
                }
            }
            
            // 4. [關鍵] 生成結束後，才統一處理選項
            await MainActor.run {
                // 過濾器：把髒髒的選項洗乾淨
                let cleanOptions = pendingOptions.filter { option in
                    // 條件：長度適中、不包含奇怪的系統指令、不包含 json 標籤
                    return option.count < 50 &&
                    !option.lowercased().contains("json") &&
                    !option.contains("返回結果") &&
                    !option.contains("items")
                }
                
                // 只有當選項是乾淨的，才顯示給玩家
                if !cleanOptions.isEmpty {
                    GameStateBridge.shared.currentOptions = cleanOptions
                } else {
                    // 萬一 AI 壞掉沒給選項，給一個預設的讓遊戲能繼續
                    GameStateBridge.shared.currentOptions = ["繼續觀察...", "轉身離開"]
                }
            }
            
        } catch {
            print("AI Error: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isGenerating = false
    }
    
    // 輔助函式：處理文字更新
    // 因為 Structured Output 的 stream 是回傳「當次生成的完整欄位內容」，而不是「這一次的 token」
    // 所以我們需要一點技巧來跟之前的劇情拼接
    private var storyHistory: String = "" // 新增一個變數存之前的劇情
    
    private func updateStoryDisplay(with currentSegment: String) {
        // 如果是剛開始生成這一段
        if storyHistory.isEmpty && !displayedStory.isEmpty {
             storyHistory = displayedStory // 把舊的存起來
        }
        
        // 畫面 = 舊劇情 + 新生成的這一段
        // 注意：每次 startStory 或 playerSelected 後，你需要把 storyHistory 更新為「當前全部」
        // 簡單修正：上面的 playerSelected 已經加了 "\n\n👉 [choice]" 到 displayedStory
        // 所以 sendPrompt 裡的 storyHistory 邏輯可以用更簡單的方式：
        
        // 修正邏輯：我們不需要 storyHistory 變數，直接 append 會有問題因為 stream 是累積的。
        // 最好的做法是：
        // 1. 在 sendPrompt 開始前，記錄當下的 displayedStory 長度或內容作為 base
        // 2. 在 loop 裡， displayedStory = base + newStory
    }
}
