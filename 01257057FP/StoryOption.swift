//
//  StoryOption.swift
//  01257057FP
//
//  Created by user05 on 2025/12/18.
//
import Foundation
import FoundationModels
import SwiftUI

// 為了讓 Tool 能跟 UI 溝通，我們用一個簡單的 Singleton 來傳遞資料
@Observable
class GameStateBridge {
    @MainActor static let shared = GameStateBridge()
    var currentOptions: [String] = []
}

struct StoryOptionTool: Tool {
    // 1. 定義 Tool 的名字，AI 會看這個名字決定要不要用
    let name = "presentOptions"
    
    // 2. 詳細描述，告訴 AI 什麼時候該用 (PDF 第 50 頁)
    let description = "當劇情進入分歧點時，呼叫此工具來顯示選項按鈕給玩家。絕對不要將選項直接寫在回應文字中。"
    
    // 3. 使用 @Generable 定義參數 (PDF 第 53 頁)
    @Generable
    struct Arguments: Codable {
        @Guide(description: "提供給玩家的選項列表 (2-4個)")
        var options: [String]
    }
    
    // 4. 執行 Tool (PDF 第 51 頁)
    func call(arguments: Arguments) async throws -> String {
        // [關鍵]：在這裡更新 UI！
        await MainActor.run {
            print("Tool 被呼叫了！選項：\(arguments.options)")
            GameStateBridge.shared.currentOptions = arguments.options
        }
        
        // 回傳給 AI 的訊息（告訴它任務完成了，可以閉嘴了）
        return "選項已顯示在螢幕上，等待玩家操作。"
    }
}
