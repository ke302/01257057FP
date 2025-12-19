//
//  SpeechManager.swift
//  01257057FP
//
//  Created by user05 on 2025/12/19.
//
import Foundation
import AVFoundation
import SwiftUI

@Observable
class SpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    var isSpeaking = false
    
    override init() {
        super.init()
        synthesizer.delegate = self
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio Session Error: \(error)")
        }
    }
    
    func speak(_ text: String) {
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 0.8
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    func setRate(_ rate: Float) {
        // AVSpeechSynthesizer 無法動態調整正在講話的語速，
        // 這裡僅預留介面，實際應用需在 speak() 時讀取此變數
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
