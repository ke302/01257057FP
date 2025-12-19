//
//  Storymanager.swift
//  01257057FP
//
//  Created by user05 on 2025/12/19.
//
import Foundation
import SwiftUI
import FoundationModels

// --- 1. 定義 AI 回傳格式 ---
@Generable
struct StoryTurn {
    @Guide(description: "一個完整的短篇故事。結尾請明確結束，不要留下懸念。禁止重複相同的語句。")
    var story: String
    
    @Guide(description: "請固定回傳包含一個字串的陣列：['再聽一個']。")
    var options: [String]
}

// --- 2. 說書人資料結構 ---
struct StorytellerInfo: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var genre: String
    var iconName: String
    var avatarData: Data?
    var color: Color
    var isCustom: Bool = false
}

// --- 3. 故事管理器 ---
@Observable
class StoryManager {
    var session: LanguageModelSession
    
    var displayedStory: String = ""
    var isGenerating: Bool = false
    var errorMessage: String?
    
    var currentOptions: [String] = []
    
    var userTopic: String = ""
    var isBGMEnabled: Bool = true
    var speechRate: Float = 0.5 {
        didSet { speechManager.setRate(speechRate) }
    }
    
    var genre: String = "中世紀奇幻"
    
    var currentStoryteller: StorytellerInfo = StorytellerInfo(
        name: "老騎士", genre: "中世紀奇幻", iconName: "shield.righthalf.filled", color: .brown
    )
    
    var customStorytellers: [StorytellerInfo] = []
    
    let contextTool = ContextAwarenessTool()
    let speechManager = SpeechManager()
    
    private var currentTask: Task<Void, Never>?
    private var storyHistory: String = ""
    
    // [新功能] 世代 ID (掛號單)，用來辨識這是哪一次的請求
    private var currentGenerationID = UUID()
    
    init() {
        self.session = LanguageModelSession()
    }
    
    func addCustomStoryteller(_ info: StorytellerInfo) {
        customStorytellers.append(info)
    }
    
    func warmUp() {
        Task { await session.prewarm() }
    }
    
    func resetGame() {
        // 取消任務
        currentTask?.cancel()
        
        // [關鍵] 換一張新的號碼牌，這樣舊的任務就算活著回來，也會因為號碼不對被擋在門外
        currentGenerationID = UUID()
        
        displayedStory = ""
        storyHistory = ""
        currentOptions = []
        isGenerating = false
        speechManager.stop()
    }
    
    func startStory() {
        resetGame()
        
        self.genre = currentStoryteller.genre
        
        // 鎖定這次的 ID
        let myID = self.currentGenerationID
        
        var specificRequest = ""
        if !userTopic.isEmpty {
            specificRequest = "，且主題關於「\(userTopic)」"
        }
        
        let personaIntro = currentStoryteller.isCustom ?
            "你扮演自訂說書人「\(currentStoryteller.name)」。" :
            "你扮演酒館裡的「\(currentStoryteller.name)」。"
        
        let instructions = """
        \(personaIntro)
        風格：「\(currentStoryteller.genre)」。
        
        【任務】
        請講述一個**獨立、完整**的短篇故事\(specificRequest)。
        
        【嚴格規則】
        1. 故事必須有明確結局 (The End)。
        2. **禁止重複**相同的段落或語句。講完就停。
        3. 字數控制在 **300 字以內**。
        4. 開場請呼叫 `checkCurrentContext` 融入現實環境。
        5. `options` 欄位請固定回傳：['再聽一個']。
        """
        
        self.session = LanguageModelSession(tools: [contextTool], instructions: instructions)
        
        currentTask = Task {
            // 把 ID 傳進去
            await sendPrompt("請檢查環境(checkCurrentContext)並開始故事。", generationID: myID)
        }
    }
    
    func playerSelected(_ choice: String) {
        // 清理介面，但不換 ID (因為這是同一次對話的延續... 不對，這裡是重新開始)
        // 為了保險，我們視為全新開始
        
        self.displayedStory = ""
        self.storyHistory = ""
        self.currentOptions = []
        speechManager.stop()
        
        if choice.contains("再聽") {
            startStory()
        }
    }
    
    // [修改] 增加 generationID 參數
    private func sendPrompt(_ text: String, generationID: UUID) async {
        // [第一道防線] 如果 ID 不對，直接不跑
        guard generationID == self.currentGenerationID else { return }
        
        await MainActor.run {
            // [第二道防線] 再次檢查 (因為切換 thread 需要時間)
            guard generationID == self.currentGenerationID else { return }
            isGenerating = true
            if storyHistory.isEmpty { storyHistory = displayedStory }
        }
        
        var currentTurnText = ""
        var pendingOptions: [String] = []
        
        do {
            let stream = session.streamResponse(to: text, generating: StoryTurn.self)
            
            for try await partial in stream {
                // [第三道防線] 串流過程中隨時檢查 ID
                // 這是你擔心的情況：如果字還沒出來你就切換了，這裡就會攔截到
                if generationID != self.currentGenerationID || Task.isCancelled {
                    // 默默離開，不要更新 UI
                    return
                }
                
                await MainActor.run {
                    // [第四道防線] UI 更新前最後確認
                    guard generationID == self.currentGenerationID else { return }
                    
                    if let newContent = partial.content.story {
                        self.displayedStory = self.storyHistory + newContent
                        currentTurnText = newContent
                    }
                    if let newOptions = partial.content.options {
                        pendingOptions = newOptions
                    }
                }
            }
            
            await MainActor.run {
                // [第五道防線] 結束後的處理
                guard generationID == self.currentGenerationID else { return }
                if Task.isCancelled { return }
                
                self.storyHistory = self.displayedStory
                let validOptions = pendingOptions.filter { !$0.isEmpty }
                
                if validOptions.isEmpty {
                    self.currentOptions = ["再聽一個"]
                } else {
                    self.currentOptions = validOptions
                }
                
                if !currentTurnText.isEmpty {
                    self.speechManager.speak(currentTurnText)
                }
            }
        } catch {
            // 只有當 ID 相符時才報錯，不然舊任務的錯誤我們不關心
            if generationID == self.currentGenerationID && !Task.isCancelled {
                print("AI Error: \(error)")
                self.errorMessage = error.localizedDescription
            }
        }
        
        await MainActor.run {
            if generationID == self.currentGenerationID {
                isGenerating = false
            }
        }
    }
}
