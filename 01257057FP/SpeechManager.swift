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
    
    private var utteranceQueue: [String] = []
    
    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    func setupAudioSession() {
        do {
            // 設定為 playback 才能在靜音模式和背景播放
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio Session Error: \(error)")
        }
    }
    
    func speak(_ text: String) {
        let cleanText = text.replacingOccurrences(of: "\"", with: "")
                                    .replacingOccurrences(of: "「", with: "")
                                    .replacingOccurrences(of: "」", with: "")
                                    .replacingOccurrences(of: "『", with: "")
                                    .replacingOccurrences(of: "』", with: "")
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        
        utteranceQueue.append(cleanText)
        processQueue()
    }
    
    private func processQueue() {
        // 如果正在講話，就等待 delegate 通知再繼續
        guard !synthesizer.isSpeaking else { return }
        
        if !utteranceQueue.isEmpty {
            let nextSentence = utteranceQueue.removeFirst()
            startSpeaking(nextSentence)
        } else {
            isSpeaking = false
        }
    }
    
    private func startSpeaking(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        utterance.rate = currentRate
        utterance.volume = currentVolume
        utterance.pitchMultiplier = 0.8
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    func setRate(_ rate: Float) { self.currentRate = rate }
    func setVolume(_ volume: Float) { self.currentVolume = volume }
    
    func stop() {
        utteranceQueue.removeAll()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
    
    // --- Delegate 修復重點 ---
    
    // 1. 正常唸完一句 -> 唸下一句
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in processQueue() }
    }
    
    // 2. [新增] 被系統打斷（如電話、Siri、鎖定螢幕） -> 也要嘗試唸下一句，不然會卡死
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in processQueue() }
    }
}
