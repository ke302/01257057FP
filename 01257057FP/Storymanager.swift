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
    
    var speechVolume: Float = 1.0 {
        didSet { speechManager.setVolume(speechVolume) }
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
    private var currentGenerationID = UUID()
    
    // 語音緩衝區
    private var speechBuffer: String = ""
    
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
        currentTask?.cancel()
        currentGenerationID = UUID()
        
        displayedStory = ""
        storyHistory = ""
        speechBuffer = ""
        currentOptions = []
        isGenerating = false
        speechManager.stop()
    }
    
    func startStory() {
        resetGame()
        self.genre = currentStoryteller.genre
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
            await sendPrompt("請檢查環境(checkCurrentContext)並開始故事。", generationID: myID)
        }
    }
    
    func playerSelected(_ choice: String) {
        self.displayedStory = ""
        self.storyHistory = ""
        self.currentOptions = []
        speechManager.stop()
        
        if choice.contains("再聽") {
            startStory()
        }
    }
    
    private func sendPrompt(_ text: String, generationID: UUID) async {
        guard generationID == self.currentGenerationID else { return }
        
        await MainActor.run {
            guard generationID == self.currentGenerationID else { return }
            isGenerating = true
            speechBuffer = ""
            if storyHistory.isEmpty { storyHistory = displayedStory }
        }
        
        var pendingOptions: [String] = []
        let sentenceDelimiters: CharacterSet = ["。", "！", "？", "\n", "…"]
        
        // [關鍵修正] 用來記錄上一回合處理到第幾個字
        var lastProcessedLength = 0
        
        do {
            let stream = session.streamResponse(to: text, generating: StoryTurn.self)
            
            for try await partial in stream {
                if generationID != self.currentGenerationID || Task.isCancelled { return }
                
                await MainActor.run {
                    guard generationID == self.currentGenerationID else { return }
                    
                    if let newFullContent = partial.content.story {
                        // 1. 更新畫面 (直接用完整內容覆蓋，因為 UI 不需要 Delta)
                        self.displayedStory = self.storyHistory + newFullContent
                        
                        // 2. [關鍵] 計算 Delta (只取新增的字) 給語音用
                        if newFullContent.count > lastProcessedLength {
                            // 算出新增的片段
                            let deltaIndex = newFullContent.index(newFullContent.startIndex, offsetBy: lastProcessedLength)
                            let deltaString = String(newFullContent[deltaIndex...])
                            
                            // 更新進度
                            lastProcessedLength = newFullContent.count
                            
                            // 只把新增的字加入緩衝區
                            self.speechBuffer += deltaString
                            self.processSpeechBuffer(delimiters: sentenceDelimiters)
                        }
                    }
                    if let newOptions = partial.content.options {
                        pendingOptions = newOptions
                    }
                }
            }
            
            await MainActor.run {
                guard generationID == self.currentGenerationID else { return }
                if Task.isCancelled { return }
                
                self.storyHistory = self.displayedStory
                let validOptions = pendingOptions.filter { !$0.isEmpty }
                
                if validOptions.isEmpty {
                    self.currentOptions = ["再聽一個"]
                } else {
                    self.currentOptions = validOptions
                }
                
                // 唸出緩衝區剩餘的字
                if !self.speechBuffer.isEmpty {
                    self.speechManager.speak(self.speechBuffer)
                    self.speechBuffer = ""
                }
            }
        } catch {
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
    
    private func processSpeechBuffer(delimiters: CharacterSet) {
        while let range = speechBuffer.rangeOfCharacter(from: delimiters) {
            let endIndex = speechBuffer.index(after: range.lowerBound)
            let sentence = String(speechBuffer[..<endIndex])
            speechManager.speak(sentence)
            speechBuffer.removeSubrange(..<endIndex)
        }
    }
}
