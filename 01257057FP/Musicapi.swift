//
//  soundsapi.swift
//  01257057FP
//
//  Created by user05 on 2025/12/22.
//
import Foundation

// 1. 定義 iTunes 回傳的資料結構
struct ITunesResponse: Codable {
    let results: [ITunesTrack]
}

struct ITunesTrack: Codable, Identifiable {
    let trackId: Int
    let trackName: String
    let artistName: String
    let previewUrl: String? // 這是我們要的 30秒 音樂網址
    
    var id: Int { trackId }
}

// 2. 網路請求服務
class MusicService {
    
    // iTunes API 不需要 API Key
    
    func fetchMusicURL(query: String) async throws -> String? {
        // 如果沒字，預設找 "Instrumental" 純音樂
        let keyword = query.isEmpty ? "Instrumental" : query
        
        // 建立 iTunes 搜尋網址
        // media=music: 找音樂
        // limit=10: 抓 10 筆回來讓我們隨機挑
        guard let encodedQuery = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encodedQuery)&media=music&limit=10") else {
            return nil
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ITunesResponse.self, from: data)
        
        // 從搜尋結果中「隨機」挑一首有試聽連結的歌
        if let randomTrack = response.results.filter({ $0.previewUrl != nil }).randomElement() {
            print("🎵 找到音樂: \(randomTrack.trackName) - \(randomTrack.artistName)")
            return randomTrack.previewUrl
        }
        
        return nil
    }
}
