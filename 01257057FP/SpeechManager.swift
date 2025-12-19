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
    
    private var currentRate: Float = 0.5
    private var currentVolume: Float = 1.0
    
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
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        
        utterance.rate = currentRate
        utterance.volume = currentVolume
        utterance.pitchMultiplier = 0.8 // 稍微低沉一點，比較有磁性
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    //更新語速 (範圍通常是 0.0 ~ 1.0，0.5 是標準)
    func setRate(_ rate: Float) {
        self.currentRate = rate
    }
    
    //更新音量 (0.0 ~ 1.0)
    func setVolume(_ volume: Float) {
        self.currentVolume = volume
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
