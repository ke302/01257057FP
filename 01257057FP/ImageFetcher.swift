//
//  ImageFetcher.swift
//  01257057FP
//
//  Created by user05 on 2025/12/11.
//
import Foundation
import UIKit

struct GoogleGenAIImageRequest: Codable {
    let instances: [InstancePrompt]
    let parameters: ImageParameters
}

struct InstancePrompt: Codable {
    let prompt: String
}

struct ImageParameters: Codable {
    let sampleCount: Int
    // 如果需要指定比例，可以加: let aspectRatio: String? // e.g., "16:9"
}

struct GoogleGenAIImageResponse: Codable {
    struct Prediction: Codable {
        let bytesBase64Encoded: String
        let mimeType: String
    }
    let predictions: [Prediction]?
}

class ImageFetcher {
    private let apiKey = "AIzaSyCxgDApv7Fkb0wZ2oawx1s62UdsTJz-KHc"
    
    // 保持原本的方法名稱，這樣 GameManager 不用改任何程式碼
    func fetchImageURL(query: String) async -> URL? {
        // 使用 Google AI Studio 的 Imagen 3 模型 Endpoint
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-001:predict?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return nil }
        
        // 構建請求內容
        // 提示詞優化：我們可以偷偷幫玩家加一點風格描述，讓生成的圖更像遊戲原畫
        let enhancedPrompt = "\(query), fantasy art style, high quality, detailed, trpg concept art"
        
        let requestBody = GoogleGenAIImageRequest(
            instances: [InstancePrompt(prompt: enhancedPrompt)],
            parameters: ImageParameters(sampleCount: 1)
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 檢查 HTTP 狀態
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("Gemini API Error: Status Code \(httpResponse.statusCode)")
                // 建議印出錯誤訊息方便除錯
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Error details: \(errorString)")
                }
                return nil
            }
            
            // 解析回傳資料
            let result = try JSONDecoder().decode(GoogleGenAIImageResponse.self, from: data)
            
            // 取出 Base64 字串並轉成圖片檔案
            if let base64String = result.predictions?.first?.bytesBase64Encoded,
               let imageData = Data(base64Encoded: base64String) {
                return saveImageToTempFile(data: imageData)
            } else {
                print("Gemini 回傳格式解析失敗或無圖片資料")
            }
            
        } catch {
            print("生圖請求失敗: \(error)")
        }
        
        return nil
    }
    
    // 輔助函式：將記憶體中的圖片資料寫入暫存檔，並回傳 URL
    private func saveImageToTempFile(data: Data) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        // 使用 UUID 確保每次檔名不同，避免快取問題
        let fileName = "\(UUID().uuidString).png"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("暫存圖片失敗: \(error)")
            return nil
        }
    }
}
