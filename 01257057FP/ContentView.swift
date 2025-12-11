//
//  ContentView.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//

// ContentView.swift
import SwiftUI
import FoundationModels
import ConfettiSwiftUI
import TipKit
import CoreHaptics

func playHaptic() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success) // 震動一下
}

struct AttackTip: Tip {
    var title: Text { Text("戰鬥提示") }
    var message: Text? { Text("點擊攻擊按鈕，AI 將會幫你擲骰子判定傷害！") }
    var image: Image? { Image(systemName: "dice.fill") }
}

struct ContentView: View {
    @State private var gameManager = DungeonGameManager()
    @State private var isGameStarted = false
    @State private var confettiTrigger = 0 // 用來觸發撒花
    
    var body: some View {
        ZStack {
            // 狀態 1: 遊戲還沒開始 -> 顯示創建頁面
            if !isGameStarted {
                CharacterCreationView(isGameStarted: $isGameStarted)
                    .transition(.move(edge: .leading)) // 轉場動畫
            }
            // 狀態 2: 遊戲進行中 -> 顯示主戰鬥畫面
            else {
                MainGameView(gameManager: gameManager, isGameStarted: $isGameStarted)
                    .transition(.opacity)
            }
            
            // 狀態 3 (特效層): 勝利撒花
            if gameManager.isVictory {
                ConfettiCannon(trigger: $confettiTrigger, num: 50, radius: 200)
            }
        }
        .animation(.easeInOut, value: isGameStarted) // 讓畫面切換有滑順動畫
        .task{
            gameManager.session.prewarm()
        }
        .onChange(of: gameManager.isVictory) { _, newValue in
            if newValue {
                confettiTrigger += 1 // 當 isVictory 變成 true 時，觸發撒花
            }
        }
    }
}
struct MainGameView: View {
    @Bindable var gameManager: DungeonGameManager
    @Binding var isGameStarted: Bool
    
    var body: some View {
        ZStack{
            // 1. 動態背景圖
            if let bgURL = gameManager.currentBackgroundImageURL {
                AsyncImage(url: bgURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .opacity(0.3) // 讓背景暗一點，不然文字看不清楚
                } placeholder: {
                    Color.black // 載入中顯示黑色
                }
            } else {
                Color.black.ignoresSafeArea() // 預設背景
            }
            // 2. 遊戲內容層 (原本的 VStack)
            VStack(spacing: 0) {
                // --- A. 頂部資訊區 (HUD) ---
                HStack {
                    Button(action: { isGameStarted = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Text("第 1 層：哥布林洞穴")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    // 這裡可以放玩家血量 (如果有做的話)
                    Label("HP: 100", systemImage: "heart.fill")
                        .foregroundStyle(.red)
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // --- B. 怪物卡片區 (如果遇到敵人的話) ---
                if let enemy = gameManager.currentEnemy {
                    VStack(spacing: 10) {
                        // 這裡可以用 AsyncImage 載入網路圖片 (加分項)
                        if let enemyURL = gameManager.currentEnemyImageURL {
                            AsyncImage(url: enemyURL) { image in
                                image.resizable().scaledToFit().frame(height: 150)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                        
                        Text(enemy.name)
                            .font(.title2)
                            .bold()
                        
                        // 怪物血條
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Enemy HP")
                                    .font(.caption)
                                    .bold()
                                Spacer()
                                Text("\(gameManager.currentEnemyHP) / \(enemy.hp)")
                                    .font(.caption)
                                    .monospacedDigit()
                            }
                            
                            ProgressView(value: Double(gameManager.currentEnemyHP), total: Double(enemy.hp))
                                .tint(.red)
                                .scaleEffect(x: 1, y: 4, anchor: .center) // 讓血條變粗一點
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .padding(.horizontal)
                        
                        Text(enemy.description)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.bottom)
                    }
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(16)
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                }
                
                // --- C. 劇情文字區 (像聊天室) ---
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(gameManager.storyText)
                            .font(.body)
                            .lineSpacing(6) // 增加行距比較好讀
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("bottom") // 用來自動捲動到底部
                    }
                    .onChange(of: gameManager.storyText) {
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
                .background(Color.gray.opacity(0.05))
                
                // --- D. 底部操作區 ---
                VStack(spacing: 16) {
                    // 勝利提示
                    if gameManager.isVictory {
                        Text("🎉 戰鬥勝利！")
                            .font(.title)
                            .bold()
                            .foregroundStyle(.green)
                            .transition(.scale)
                    }
                    
                    HStack(spacing: 20) {
                        // 探索按鈕
                        Button {
                            Task { await gameManager.encounterEnemy() }
                        } label: {
                            VStack {
                                Image(systemName: "map.fill")
                                    .font(.title)
                                Text("探索")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.gradient)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        .disabled(gameManager.currentEnemyHP > 0) // 戰鬥中不能探索
                        
                        HStack(spacing: 15) {
                            // 防禦按鈕
                            Button {
                                gameManager.defend()
                            } label: {
                                VStack {
                                    Image(systemName: "shield.fill")
                                    Text("防禦")
                                }
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(10)
                            }
                            
                            // 攻擊按鈕 (大)
                            Button {
                                Task { await gameManager.performFastAttack(damage: 15) } // 呼叫快速攻擊
                            } label: {
                                VStack {
                                    Image(systemName: "sword.fill")
                                        .font(.title)
                                    Text("攻擊")
                                }
                                .frame(width: 100, height: 80)
                                .background(Color.red.gradient)
                                .foregroundStyle(.white)
                                .cornerRadius(15)
                                .shadow(radius: 5)
                            }
                            
                            // 補血按鈕 (帶冷卻遮罩)
                            Button {
                                gameManager.heal()
                            } label: {
                                ZStack {
                                    VStack {
                                        Image(systemName: "cross.case.fill")
                                        Text("治療")
                                    }
                                    // 冷卻遮罩
                                    if gameManager.healCooldown > 0 {
                                        Color.black.opacity(0.5)
                                        Text("\(gameManager.healCooldown)")
                                            .foregroundStyle(.white)
                                            .font(.title)
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(10)
                            }
                            .disabled(gameManager.healCooldown > 0)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial) // 毛玻璃背景
            }
        }
    }
}

