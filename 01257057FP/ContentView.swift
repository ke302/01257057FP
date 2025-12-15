//
//  ContentView.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//

// ContentView.swift
//
import SwiftUI
import FoundationModels
import ConfettiSwiftUI

// 定義遊戲的三個階段
enum GameState {
    case creatingCharacter // 1. 創角
    case settingWorld      // 2. 世界設定
    case playing           // 3. 遊戲進行中
}

struct ContentView: View {
    @State private var gameManager = DungeonGameManager()
    @State private var gameState: GameState = .creatingCharacter
    @State private var confettiTrigger = 0
    
    var body: some View {
        NavigationStack {
            switch gameState {
            case .creatingCharacter:
                CharacterCreationView(gameState: $gameState, gameManager: gameManager)
                
            case .settingWorld:
                WorldSettingView(gameManager: gameManager, gameState: $gameState)
                
            case .playing:
                MainGameView(gameManager: gameManager, gameState: $gameState)
            }
        }
        // 監聽評價視窗
        .sheet(isPresented: $gameManager.showEvaluation) {
            EvaluationView(report: gameManager.evaluationReport) {
                // 關閉評價後，回到主選單或重置
                gameState = .creatingCharacter
                gameManager = DungeonGameManager() // 重置遊戲
            }
        }
    }
}

// 評價彈窗
struct EvaluationView: View {
    let report: String
    var onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("📜 冒險評價")
                .font(.largeTitle)
                .padding()
            ScrollView {
                Text(report)
                    .padding()
            }
            Button("回到主標題") {
                onDismiss()
            }
            .padding()
        }
    }
}

// 翻新後的主遊戲畫面
struct MainGameView: View {
    @Bindable var gameManager: DungeonGameManager
    @Binding var gameState: GameState
    @State private var playerInput: String = ""
    
    var body: some View {
        ZStack {
            // 背景圖
            if let bgURL = gameManager.currentBackgroundImageURL {
                AsyncImage(url: bgURL) { image in
                    image.resizable().scaledToFill().ignoresSafeArea().opacity(0.2)
                } placeholder: { Color.black.ignoresSafeArea() }
            } else {
                Color.black.ignoresSafeArea()
            }
            
            VStack {
                // 頂部功能列
                HStack {
                    Text("HP: \(gameManager.playerHP)")
                        .font(.headline)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                    
                    Spacer()
                    
                    Button("結束冒險") {
                        Task { await gameManager.endGameAndEvaluate() }
                    }
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(8)
                }
                .padding()
                
                // 故事卷軸
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            // 修正 1 & 2: 使用 LocalizedStringKey 強制渲染 Markdown，並加上美化
                            Text(.init(gameManager.storyText))
                                .font(.body)
                                .lineSpacing(6)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id("bottom") // 自動捲動的錨點
                        }
                        .background(.ultraThinMaterial) // 修正 3: 加入毛玻璃背景，提升可讀性
                        .cornerRadius(16) // 圓角
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1) // 加個淡淡的邊框更有質感
                        )
                        .padding(.horizontal) // 外距：讓整個框框不要貼著螢幕左右邊緣
                        .padding(.top, 10) // 頂部留點空間
                        .padding(.bottom, 80) // 底部留多一點空間，以免被輸入框擋住
                    }
                    .onChange(of: gameManager.storyText) {
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
                
                // 底部輸入區
                HStack(spacing: 10) {
                    TextField("輸入行動...", text: $playerInput)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 8)
                    
                    Button {
                        let input = playerInput
                        playerInput = ""
                        Task { await gameManager.processPlayerInput(input) }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 34))
                            .foregroundStyle(.blue)
                    }
                    .disabled(playerInput.isEmpty)
                }
                .padding()
                .background(.bar) // 鍵盤上方的背景條
            }
        }
    }
}

