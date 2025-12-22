//
//  CustomStorytellerView.swift
//  01257057FP
//
//  Created by user05 on 2025/12/19.
//
import SwiftUI
import PhotosUI
import TipKit

struct ColorSoulTip: Tip {
    var title: Text { Text("什麼是靈魂顏色？") }
    var message: Text? { Text("這個顏色將會決定 App 的介面主題色，以及說書時的撒花特效顏色。") }
    var image: Image? { Image(systemName: "paintpalette") }
}
struct CustomStorytellerView: View {
    // 這裡用 Bindable 才能寫入新角色到 Manager
    @Bindable var gameManager: StoryManager
    @Environment(\.dismiss) var dismiss
    
    // 暫存的新角色資料
    @State private var tempName: String = ""
    @State private var selectedGenre: String = "中世紀奇幻"
    @State private var themeColor: Color = .blue
    
    // PhotosPicker 狀態
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var avatarData: Data?
    
    let genres = ["中世紀奇幻", "賽博龐克偵探", "克蘇魯神話", "都市傳說", "療癒童話"]
    let colorTip = ColorSoulTip()
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.08, blue: 0.05).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    
                    Text("招募新說書人")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .padding(.top)
                    
                    // 1. 選頭像 (PhotosPicker)
                    VStack {
                        if let avatarImage {
                            avatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(themeColor, lineWidth: 3))
                        } else {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 80))
                                .foregroundStyle(.gray)
                        }
                        
                        PhotosPicker(selection: $avatarItem, matching: .images) {
                            Text("從相簿選擇頭像")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(20)
                                .foregroundStyle(.orange)
                        }
                        .onChange(of: avatarItem) {
                            Task {
                                if let data = try? await avatarItem?.loadTransferable(type: Data.self) {
                                    avatarData = data
                                    if let uiImage = UIImage(data: data) {
                                        avatarImage = Image(uiImage: uiImage)
                                    }
                                }
                            }
                        }
                    }
                    
                    // 2. 設定 AI 角色
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("稱號 (Name)").foregroundStyle(.gray)
                            TextField("例如：流浪詩人", text: $tempName)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .foregroundStyle(.white)
                                .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("擅長故事 (Genre)").foregroundStyle(.gray)
                            Picker("風格", selection: $selectedGenre) {
                                ForEach(genres, id: \.self) { genre in
                                    Text(genre).tag(genre)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.orange)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        ColorPicker("靈魂顏色 (Color)", selection: $themeColor)
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                        
                        TipView(colorTip, arrowEdge: .top)
                            .tipBackground(.blue.opacity(0.2)) // 可以自訂背景色
                            .tint(.white)
                    }
                    .padding(.horizontal)
                    
                    // 3. 確認按鈕 (不再是 NavigationLink)
                    Button(action: {
                        // 建立新角色物件
                        let newStoryteller = StorytellerInfo(
                            name: tempName,
                            genre: selectedGenre,
                            iconName: "person.fill", // 預設圖示
                            avatarData: avatarData,
                            color: themeColor,
                            isCustom: true
                        )
                        
                        // 存入 Manager
                        gameManager.addCustomStoryteller(newStoryteller)
                        
                        // 返回酒館
                        dismiss()
                    }) {
                        Text("確認招募")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(tempName.isEmpty ? Color.gray : Color.orange)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                    .disabled(tempName.isEmpty)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}
