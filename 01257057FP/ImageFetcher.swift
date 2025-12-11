//
//  ImageFetcher.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//
import Foundation

struct UnsplashResult: Codable {
    let urls: UnsplashURLs
}

struct UnsplashURLs: Codable {
    let regular: String
    let small: String
}

class ImageFetcher {
    // 替換成你的 Access Key
    private let accessKey = "coD2voTNhjkAIi3XdNkegx3p2Hr7xhhr20Y4xiwKACs"
    
    func fetchImageURL(query: String) async -> URL? {
        // 簡單處理一下 query，把空白換成 +
        let formattedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "dungeon"
        let urlString = "https://api.unsplash.com/photos/random?query=\(formattedQuery)&client_id=\(accessKey)"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(UnsplashResult.self, from: data)
            return URL(string: result.urls.regular)
        } catch {
            print("抓圖失敗: \(error)")
            return nil
        }
    }
}
