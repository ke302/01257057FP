//
//  Dice.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//
import Foundation
import FoundationModels

struct DiceRollTool: Tool {
    // 這是給 AI 看的名字，要準確
    let name = "rollDice"
    // 這是給 AI 看的說明，告訴它什麼時候用
    let description = "當需要進行機率檢定、攻擊判定或計算傷害時，呼叫此工具擲骰子。"

    @Generable
    struct Arguments {
        @Guide(description: "骰子面數 (例如 20 代表 D20)", .range(4...100))
        var sides: Int
        @Guide(description: "骰子數量", .range(1...10))
        var count: Int
    }

    func call(arguments: Arguments) async throws -> String {
        var total = 0
        var details: [String] = []
        
        for _ in 0..<arguments.count {
            let roll = Int.random(in: 1...arguments.sides)
            total += roll
            details.append(String(roll))
        }
        
        // 回傳字串給 AI，讓它根據這個結果去編故事
        return "擲骰結果: [\(details.joined(separator: ", "))], 總和: \(total)"
    }
}
