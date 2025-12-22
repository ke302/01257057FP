//
//  BGMmanager.swift
//  01257057FP
//
//  Created by user05 on 2025/12/22.
//
import Foundation
import AVFoundation

@Observable
class BGMManager {
    private var player: AVPlayer?
    var isPlaying = false
    
    // 播放來自 URL 的音樂
    func playMusic(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        // 設定 Audio Session 確保聲音不會被靜音模式吃掉
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio Session 設定失敗: \(error)")
        }
        
        // 建立 AVPlayerItem
        let playerItem = AVPlayerItem(url: url)
        
        // 如果已經有播放器，替換項目即可；否則建立新的
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        
        player?.volume = 0.3 // 背景音樂小聲一點
        player?.play()
        isPlaying = true
        
        // 監聽播放結束，實現循環播放
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
    }
    
    func stop() {
        player?.pause()
        isPlaying = false
    }
    
    func setVolume(_ volume: Float) {
        player?.volume = volume
    }
}
