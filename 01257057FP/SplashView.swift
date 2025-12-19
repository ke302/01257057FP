//
//  SplashView.swift
//  01257057FP
//
//  Created by user05 on 2025/12/19.
//
import SwiftUI

struct SplashView: View {
    @Binding var isActive: Bool
    
    // 控制燭光搖曳
    @State private var flameOpacity = 0.6
    @State private var flameScale = 1.0
    
    var body: some View {
        ZStack {
            // 背景：深邃的午夜藍黑
            Color(red: 0.05, green: 0.05, blue: 0.08).ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 燭光圖示 (模擬火光)
                ZStack {
                    // 外層光暈 (呼吸效果)
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 100, height: 100)
                        .blur(radius: 40)
                        .opacity(flameOpacity)
                        .scaleEffect(flameScale)
                    
                    // 核心圖示
                    Image(systemName: "flame.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 80)
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, .orange, .red], startPoint: .top, endPoint: .bottom)
                        )
                }
                
                VStack(spacing: 10) {
                    Text("The Wanderer's Inn")
                        .font(.system(size: 36, weight: .bold, design: .serif)) // 使用襯線體
                        .foregroundStyle(.orange.opacity(0.9))
                        .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 0)
                    
                    Text("旅人的終點，故事的起點")
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(2)
                }
            }
        }
        .onAppear {
            // 1. 啟動燭光搖曳動畫 (Loop)
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                flameOpacity = 0.9
                flameScale = 1.1
            }
            
            // 2. 3秒後進入主畫面
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 1.0)) {
                    self.isActive = true
                }
            }
        }
    }
}
