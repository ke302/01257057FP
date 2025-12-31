//
//  StorytellerItem.swift
//  01257057FP
//
//  Created by user05 on 2025/12/31.
//
import Foundation
import SwiftData
import SwiftUI

@Model
class StorytellerItem {
    var id: UUID
    var name: String
    var genre: String
    var iconName: String
    var avatarData: Data?
    
    // Color 無法直接存，改存 RGB
    var red: Double
    var green: Double
    var blue: Double
    
    init(name: String, genre: String, iconName: String, avatarData: Data? = nil, color: Color) {
        self.id = UUID()
        self.name = name
        self.genre = genre
        self.iconName = iconName
        self.avatarData = avatarData
        
        // 解析 Color
        if let components = color.cgColor?.components, components.count >= 3 {
            self.red = Double(components[0])
            self.green = Double(components[1])
            self.blue = Double(components[2])
        } else {
            self.red = 0.5; self.green = 0.5; self.blue = 0.5
        }
    }
    
    // 轉回 SwiftUI Color 方便使用
    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
    
    // 轉回原本的 StorytellerInfo 結構 (為了相容既有程式碼)
    var toInfo: StorytellerInfo {
        StorytellerInfo(name: name, genre: genre, iconName: iconName, avatarData: avatarData, color: color, isCustom: true)
    }
}
