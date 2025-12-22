//
//  _1257057FPApp.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//

import SwiftUI
import TipKit

@main
struct _1257057FPApp: App {
    @State private var showMainApp = false
    init() {
        // 開發測試用：每次啟動 App 都重置 Tip 狀態，讓你還能再看到它們
        // try? Tips.resetDatastore()
        
        try? Tips.configure([
            .displayFrequency(.immediate), // 設定為立即顯示，不用等
            .datastoreLocation(.applicationDefault)
        ])
    }
    var body: some Scene {
        WindowGroup {
            if showMainApp {
                // 動畫結束後，顯示酒館大廳
                TavernView()
            } else {
                // 一開始顯示啟動畫面，並傳入 binding 來控制切換
                SplashView(isActive: $showMainApp)
            }
        }
    }
}
