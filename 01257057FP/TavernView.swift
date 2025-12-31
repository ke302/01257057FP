//
//  TavernView.swift
//  01257057FP
//
//  Created by user05 on 2025/12/19.
//
import SwiftUI
import TipKit
import SwiftData

struct MagicOrderTip: Tip {
    var title: Text { Text("點歌小秘訣") }
    var message: Text? { Text("輸入情境關鍵字（如：雨天、咖啡廳），酒館會為你播放專屬背景音樂喔！") }
    var image: Image? { Image(systemName: "music.quarternote.3") }
}

struct CreateCharacterTip: Tip {
    
    // 定義一個參數來追蹤是否已經有自訂角色
    @Parameter
    static var hasCustomCharacter: Bool = false
    
    var title: Text { Text("招募新夥伴") }
    var message: Text? { Text("覺得內建角色不夠用？點擊這裡創造屬於你的 AI 旅人！") }
    
    var rules: [Rule] {
        // 規則：當 hasCustomCharacter 為 false 時才顯示
        #Rule(Self.$hasCustomCharacter) { $0 == false }
    }
}

struct TavernView: View {
    @State private var gameManager = StoryManager()
    @State private var showSettings = false
    @State private var themeColor: Color = .brown
    @Query var savedStorytellers: [StorytellerItem]
    @Environment(\.modelContext) var context
    @Environment(\.modelContext) private var modelContext
    // 內建的說書人列表
    let presets = [
        StorytellerInfo(name: "老騎士", genre: "中世紀奇幻", iconName: "shield.righthalf.filled", color: .brown),
        StorytellerInfo(name: "神秘人", genre: "克蘇魯神話", iconName: "eye.fill", color: .purple),
        StorytellerInfo(name: "時空客", genre: "賽博龐克偵探", iconName: "bolt.fill", color: .cyan)
    ]
    let magicOrderTip = MagicOrderTip()
    let createCharTip = CreateCharacterTip()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景：使用深色或主題色
                Color(red: 0.1, green: 0.08, blue: 0.05).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // --- 頂部導航列 ---
                    HStack {
                        VStack(alignment: .leading) {
                            Text("The Wanderer's Inn")
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundStyle(.orange)
                            Text("流浪者酒館")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        // 酒杯按鈕 -> 開啟設定
                        Button(action: { showSettings = true }) {
                            Image(systemName: "wineglass.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                                .padding(10)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // --- 點單區 ---
                            VStack(alignment: .leading, spacing: 10) {
                                Text("📝 特別點單")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                
                                TextField("例如：暴風雨、初戀...", text: $gameManager.userTopic)
                                    .padding()
                                    .background(Color(red: 0.95, green: 0.92, blue: 0.85)) // 紙張色
                                    .foregroundStyle(.black)
                                    .cornerRadius(8)
                                    .onSubmit {
                                        // [選用] 使用者按下 Enter 時，可以單獨測試音樂，而不開始講故事
                                        Task {
                                            if let url = try? await gameManager.musicService.fetchMusicURL(query: gameManager.userTopic) {
                                                
                                                // 切回主執行緒播放 (雖然 playMusic 裡通常有處理，但加上 MainActor 更保險)
                                                await MainActor.run {
                                                    gameManager.bgmManager.playMusic(from: url)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                    .popoverTip(magicOrderTip, arrowEdge: .top)
                                
                                Divider().background(Color.white.opacity(0.2)).padding(.vertical)
                                
                                // --- 說書人列表 ---
                                Text("選擇一位旅人")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 16) {
                                    
                                    // A. 自訂說書人 (傳入 gameManager)
                                    NavigationLink(destination: CustomStorytellerView(gameManager: gameManager)) {
                                        HStack {
                                            ZStack {
                                                Circle().fill(Color.gray.opacity(0.3)).frame(width: 50, height: 50)
                                                Image(systemName: "plus")
                                                    .font(.title)
                                                    .foregroundStyle(.white)
                                            }
                                            
                                            Text("邀請新的旅人 (自訂角色)")
                                                .font(.system(size: 18, weight: .bold, design: .serif))
                                                .foregroundStyle(.white)
                                            
                                            Spacer()
                                            Image(systemName: "chevron.right").foregroundStyle(.gray)
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5])))
                                    }
                                    .popoverTip(createCharTip, arrowEdge: .bottom)
                                    
                                    // B. 內建說書人
                                    ForEach(presets, id: \.name) { storyteller in
                                        // [修正] 這裡必須傳入 gameManager 給 ContentView
                                        NavigationLink(destination: ContentView(gameManager: gameManager)) {
                                            StorytellerCard(info: storyteller)
                                        }
                                        .simultaneousGesture(TapGesture().onEnded {
                                            // 更新 Manager 的當前角色
                                            gameManager.currentStoryteller = storyteller
                                            gameManager.genre = storyteller.genre
                                        })
                                    }
                                    // C. 新說書人
                                    ForEach(savedStorytellers) { item in
                                        NavigationLink(destination: ContentView(gameManager: gameManager)) {
                                            // 轉成 Info 格式顯示
                                            StorytellerCard(info: item.toInfo)
                                        }
                                        .simultaneousGesture(TapGesture().onEnded {
                                            // 轉成 Info 格式傳給 Manager
                                            gameManager.currentStoryteller = item.toInfo
                                            gameManager.genre = item.genre
                                        })
                                        // (選用) 加上刪除功能
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                // 1. 從資料庫刪除該項目
                                                modelContext.delete(item)
                                                
                                                // 2. (選用) 如果被刪除的是當前選中的角色，重置為預設
                                                if gameManager.currentStoryteller.name == item.name {
                                                    if let defaultRole = presets.first {
                                                        gameManager.currentStoryteller = defaultRole
                                                        gameManager.genre = defaultRole.genre
                                                    }
                                                }
                                            } label: {
                                                Label("解雇", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 40)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(gameManager: gameManager, themeColor: $themeColor)
                }
            }
            .accentColor(.orange)
        }
        .onAppear {
            gameManager.startLobbyMusic()
        }
    }
   
    
    // 輔助視圖：卡片樣式
    struct StorytellerCard: View {
        let info: StorytellerInfo
        
        var body: some View {
            HStack(spacing: 15) {
                // 如果有自訂照片，優先顯示照片
                if let data = info.avatarData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(info.color, lineWidth: 2))
                } else {
                    // 否則顯示內建 SF Symbol
                    Image(systemName: info.iconName)
                        .font(.title)
                        .foregroundStyle(info.color)
                        .frame(width: 50, height: 50)
                        .background(info.color.opacity(0.2))
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading) {
                    Text(info.name)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                    Text(info.genre)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
        }
    }
}
