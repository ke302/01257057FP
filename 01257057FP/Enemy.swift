//
//  Enemy.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//
import FoundationModels

@Generable
struct Enemy {
    @Guide(description: "怪物的名稱，聽起來要具有威脅性")
    let name: String
    
    @Guide(description: "怪物的詳細外觀描述，包含顏色、體型和特徵")
    let description: String
    
    @Guide(description: "怪物的生命值", .range(20...100))
    let hp: Int
    
    @Guide(description: "怪物的攻擊力", .range(5...15))
    let attack: Int
    
    @Guide(description: "用於搜尋圖片的英文關鍵字，例如 'fire dragon' 或 'goblin'")
    let imageKeyword: String
}
