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
    var currentEnemy: Enemy?
    var storyText: String = ""
    var isVictory: Bool = false
    var currentEnemyHP: Int = 0
    var playerHP: Int = 100
    var isDefending: Bool = false
    var healCooldown: Int = 0
    
    init() {
        let diceTool = DiceRollTool()
        // 設定 AI 的人設 (Instructions)
        let instructions = """
        你是一個 TRPG 的地下城主 (DM)。
        1. 遇到戰鬥或需要機率判定時，**必須**呼叫 'rollDice' tool，不能自己編造數字。
        2. 根據擲骰結果描述發生的事情 (大於 10 成功，小於 10 失敗)。
        3. 語氣要生動、緊張。
        """
        
        self.session = LanguageModelSession(
            tools: [diceTool],
            instructions: instructions
        )
    }
    
    // 遇到敵人時呼叫此函式
    func encounterEnemy() async {
        do {
            self.isVictory = false
            
            let prompt = "玩家進入了一個新的房間，請生成一隻隨機的怪物。"
            let response = try await session.respond(to: prompt, generating: Enemy.self)
            self.currentEnemy = response.content
            
            if let enemy = self.currentEnemy {
                            self.currentEnemyHP = enemy.hp
                            await performStoryUpdate(prompt: "描述玩家遭遇 \(enemy.name) 的情境，包含它的外觀 \(enemy.description)。")
                        }
        } catch {
            print("生成怪物失敗: \(error)")
        }
    }
    
    // 一般劇情推進 (Streaming)
    func performFastAttack(damage: Int) async {
        // 1. Swift 立即處理數值
        self.currentEnemyHP -= damage
        if self.healCooldown > 0 { self.healCooldown -= 1 } // 減少冷卻
        
        // 2. 判斷死活
        if currentEnemyHP <= 0 {
            currentEnemyHP = 0
            isVictory = true
            // 只有勝利時才叫 AI 寫長篇大論
            await performStoryUpdate(prompt: "怪物被擊敗了！請描述勝利畫面。")
        } else {
            // 3. 戰鬥中，讓 AI 講短一點，甚至不要講話，只更新狀態
            // 技巧：不要每次攻擊都叫 AI 生成故事，可以每 3 次攻擊才生成一次，減少等待
            if Int.random(in: 1...3) == 1 {
                await performStoryUpdate(prompt: "玩家造成 \(damage) 傷害。簡短描述戰鬥動作。")
            }
        }
    }
    
    func defend() {
        isDefending = true
        // 這裡可以只用 Swift 顯示 "你舉起了盾牌"，完全不用 AI，速度最快
        storyText += "\n🛡️ 你舉起盾牌，準備抵擋下一次攻擊！"
    }

    // 喝水技能
    func heal() {
        guard healCooldown == 0 else { return }
        playerHP += 20
        healCooldown = 3 // 需冷卻 3 回合
        storyText += "\n❤️ 你喝下藥水，恢復了 20 點生命。"
    }
    
    // 輔助函式：更新故事文字 (Streaming)
        private func performStoryUpdate(prompt: String) async {
            let stream = session.streamResponse(to: prompt) // 使用串流回應 [cite: 746]
            
            do {
                for try await partial in stream {
                    self.storyText = partial.content
                }
            } catch {
                print("劇情生成錯誤: \(error)")
            }
        }
    
}

