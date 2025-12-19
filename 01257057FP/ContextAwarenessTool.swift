//
//  ContextAwarenessTool.swift
//  01257057FP
//
//  Created by user05 on 2025/12/19.
//
import Foundation
import FoundationModels
import UIKit

struct ContextAwarenessTool: Tool {
    let name = "checkCurrentContext"
    let description = "Retrieves the user's real-world context."
    
    @Generable
    struct Arguments {}
    
    func call(arguments: Arguments) async throws -> String {
        // [修正] 使用 MainActor.run 來存取 UI 相關 API
        let contextInfo = await MainActor.run { () -> String in
            let device = UIDevice.current
            device.isBatteryMonitoringEnabled = true
            let batteryLevel = Int(device.batteryLevel * 100)
            let isCharging = device.batteryState == .charging || device.batteryState == .full
            
            let hour = Calendar.current.component(.hour, from: Date())
            let timeDesc = (6...18).contains(hour) ? "Daytime" : "Night"
            
            return "Time: \(hour):00 (\(timeDesc)), Battery: \(batteryLevel)% (Charging: \(isCharging))"
        }
        
        return contextInfo
    }
}

