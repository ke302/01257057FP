//
//  ContentView.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//
import SwiftUI
import FoundationModels

struct ContentView: View {
    @State private var gameManager = StoryGameManager()
    // 監聽 Tool 傳來的資料
    var bridge = GameStateBridge.shared
    
    var body: some View {
        NavigationStack {
            VStack {
                // 1. 故事顯示區 (ScrollView + Text)
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(gameManager.displayedStory)
                            .padding()
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("bottom")
                    }
                    .onChange(of: gameManager.displayedStory) {
                        // 自動捲動到底部
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                
                Divider()
                
                // 2. 選項區 (根據 Tool 的結果顯示按鈕)
                if !bridge.currentOptions.isEmpty {
                    VStack(spacing: 12) {
                        Text("做出你的選擇：")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ForEach(bridge.currentOptions, id: \.self) { option in
                            Button(action: {
                                Task {
                                    await gameManager.playerSelected(option)
                                }
                            }) {
                                Text(option)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if gameManager.isGenerating {
                    // AI 正在思考或打字中
                    HStack {
                        ProgressView()
                        Text("故事生成中...")
                            .font(.caption)
                    }
                    .padding()
                } else if gameManager.displayedStory.isEmpty {
                    // 尚未開始遊戲
                    Button("開始冒險") {
                        Task { await gameManager.startStory() }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .navigationTitle("互動小說 AI")
            .toolbar {
                // 設定按鈕
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { /* 顯示設定頁面 */ }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onAppear {
            // [效能優化] PDF 第 61 頁
            gameManager.warmUp()
        }
    }
}

