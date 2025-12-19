//
//  ContentView.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//
import SwiftUI
import FoundationModels
import TipKit
import ConfettiSwiftUI

struct StartTip: Tip {
    var title: Text { Text("準備好了嗎？") }
    var message: Text? { Text("點擊播放，讓 AI 為你講一個睡前故事。") }
}

struct ContentView: View {
    @Bindable var gameManager: StoryManager
    
    @State private var showSettings = false
    @State private var themeColor: Color = .blue
    @State private var confettiCounter = 0
    @State private var storyImageURL: URL?
    
    let imageFetcher = ImageFetcher()
    let startTip = StartTip()
    
    var body: some View {
        NavigationStack {
            ZStack {
                gameManager.currentStoryteller.color.opacity(0.05).ignoresSafeArea()

                VStack {
                    if let url = storyImageURL {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 200).cornerRadius(12).padding().shadow(radius: 5)
                    }
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(gameManager.displayedStory)
                                .padding()
                                .font(.system(size: 18, weight: .regular, design: .serif))
                                .lineSpacing(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id("bottom")
                        }
                        .onChange(of: gameManager.displayedStory) {
                            withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                        }
                    }
                    
                    Divider()
                    
                    if !gameManager.currentOptions.isEmpty {
                        VStack(spacing: 12) {
                            Text("故事結束了")
                                .font(.caption).foregroundStyle(.secondary)
                            
                            ForEach(gameManager.currentOptions, id: \.self) { option in
                                Button(action: {
                                    // [修正] 不需要 Task await 了，直接呼叫
                                    gameManager.playerSelected(option)
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text(option)
                                    }
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(gameManager.currentStoryteller.color)
                                    .foregroundColor(.white)
                                    .cornerRadius(25)
                                }
                            }
                        }
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                    } else if gameManager.isGenerating {
                        HStack(spacing: 15) {
                            ProgressView().tint(gameManager.currentStoryteller.color)
                            Text("\(gameManager.currentStoryteller.name) 正在講述...").font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding()
                        
                    } else if gameManager.displayedStory.isEmpty {
                        Button(action: {
                            confettiCounter += 1
                            // [修正] 故事邏輯由 Manager 自己跑，我們這邊只負責生圖
                            gameManager.startStory()
                            
                            Task {
                                await generateSceneImage()
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("聽故事")
                            }
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(gameManager.currentStoryteller.color)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(radius: 3)
                        }
                        .padding(.horizontal, 40).padding(.bottom, 20).popoverTip(startTip)
                    }
                }
                GeometryReader { geo in
                    // 只有當畫面寬度大於 0 時，才載入撒花元件
                    if geo.size.width > 0 {
                        ConfettiCannon(trigger: $confettiCounter, num: 50, confettis: [.text("✨"), .text("🌙"), .shape(.circle)])
                    }
                }
                // 讓這個 GeometryReader 不干擾排版
                .allowsHitTesting(false)
            }
            .navigationTitle(gameManager.currentStoryteller.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill").foregroundStyle(gameManager.currentStoryteller.color)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(gameManager: gameManager, themeColor: $themeColor)
            }
            .task { try? Tips.configure() }
        }
        .onAppear {
            gameManager.warmUp()
            if !gameManager.displayedStory.isEmpty && storyImageURL == nil {
                Task { await generateSceneImage() }
            }
        }
        .onDisappear {
            // 離開時，這行會觸發 StoryManager 裡的 cancel()，確保乾淨
            gameManager.resetGame()
        }
    }
    
    func generateSceneImage() async {
        let prompt = "A cinematic scene for a \(gameManager.genre) story, high quality, artstation style, warm lighting"
        if let url = await imageFetcher.fetchImageURL(query: prompt) {
            self.storyImageURL = url
        }
    }
}
