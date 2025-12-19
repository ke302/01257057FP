//
//  _1257057FPApp.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//

import SwiftUI

@main
struct _1257057FPApp: App {
    @State private var showMainApp = false
    
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
