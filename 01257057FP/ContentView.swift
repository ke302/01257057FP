//
//  ContentView.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//
import SwiftUI
import FoundationModels
import TipKit // [需求] TipKit
import ConfettiSwiftUI // [需求] SPM

struct StartTip: Tip {
    var title: Text { Text("開始冒險") }
    var message: Text? { Text("點擊這裡開始你的故事！") }
}

struct ContentView: View {
    @State private var gameManager = StoryGameManager()
    @State private var showSettings = false
    @State private var themeColor: Color = .blue // 主題色狀態
    @State private var confettiCounter = 0 // [需求] SPM: 撒花特效計數器
    @State private var storyImageURL: URL?
    
    let imageFetcher = ImageFetcher() // 你的 ImageFetcher
    var bridge = GameStateBridge.shared
    
    // 實例化 Tip
    let startTip = StartTip()
    
    var body: some View {
        NavigationStack {
            ZStack{
                VStack {
                    //  顯示網路圖片 (如果有的話)
                    if let url = storyImageURL {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding()
                    }
                    
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
                            confettiCounter += 1
                            
                            Task { await gameManager.startStory()
                                await generateSceneImage()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(themeColor)
                        .padding()
                        .popoverTip(startTip)
                        
                    }
                }
                ConfettiCannon(trigger: $confettiCounter, num: 50, confettis: [.text("✨"), .text("🚀"), .shape(.circle)])
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
            .sheet(isPresented: $showSettings) {
                // 傳遞 Binding
                SettingsView(gameManager: gameManager, themeColor: $themeColor)
            }
            .task {
                // 初始化 TipKit
                try? Tips.configure()
            }
        }
        .onAppear {
            // [效能優化] PDF 第 61 頁
            gameManager.warmUp()
        }
        
    }
    func generateSceneImage() async {
        // 使用你的 ImageFetcher
        // 注意：記得去 ImageFetcher.swift 填入你的 API Key
        let prompt = "A cinematic scene for a \(gameManager.genre) story, high quality, artstation style"
        if let url = await imageFetcher.fetchImageURL(query: prompt) {
            self.storyImageURL = url
        }
    }
}
