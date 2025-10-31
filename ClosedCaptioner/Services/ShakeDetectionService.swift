//
//  ShakeDetectionService.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Foundation
import CoreMotion

class ShakeDetectionService: ObservableObject {
    static let shared = ShakeDetectionService()
    
    private let motionManager = CMMotionManager()
    private var recentMotionData: [(acceleration: Double, timestamp: TimeInterval)] = []
    private let motionHistoryWindow: TimeInterval = 0.3 // Keep last 300ms of motion data
    private var backgroundMonitoringTimer: Timer?
    private let MAX_SHAKE_STRENGTH: Double = 10.0
    
    private init() {
        setupMotionManager()
        startBackgroundMonitoring()
    }
    
    private func setupMotionManager() {
        guard motionManager.isAccelerometerAvailable else {
            print("⚠️ Accelerometer not available")
            return
        }
        
        // Use a moderate update interval for background monitoring
        motionManager.accelerometerUpdateInterval = 0.03 // ~33Hz (30ms updates)
    }
    
    private func startBackgroundMonitoring() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        // Continuously monitor accelerometer in the background at low frequency
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data else { return }
            
            let timestamp = data.timestamp
            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z
            
            // Calculate magnitude (total acceleration)
            let magnitude = sqrt(x*x + y*y + z*z)
            
            // User acceleration (excluding gravity ~1.0)
            let userAcceleration = abs(magnitude - 1.0)
            
            // Store recent motion data
            self.recentMotionData.append((acceleration: userAcceleration, timestamp: timestamp))
            
            // Keep only data within the time window
            let cutoffTime = timestamp - self.motionHistoryWindow
            self.recentMotionData.removeAll { $0.timestamp < cutoffTime }
        }
    }
    
    func getShakeStrength() -> Double {
        guard !recentMotionData.isEmpty else {
            return 0.0
        }
        
        // Use the recently collected motion data to calculate strength
        let accelerations = recentMotionData.map { $0.acceleration }
        
        // Calculate statistics
        let mean = accelerations.reduce(0, +) / Double(accelerations.count)
        let maxAcceleration = accelerations.max() ?? 0.0
        
        // Calculate variance (measure of intensity variation)
        let variance = accelerations.map { pow($0 - mean, 2) }.reduce(0, +) / Double(accelerations.count)
        
        // Combined shake strength formula:
        // - Max acceleration (peak force) - 50% weight
        // - Variance (consistency/intensity variation) - 30% weight
        // - Mean (average intensity) - 20% weight
        let strength = (maxAcceleration * 0.5) + (sqrt(variance) * 0.3) + (mean * 0.2)
        
        // Scale to reasonable range (0.0 to ~MAX_SHAKE_STRENGTH)
        // Typical shake values: 0.5-2.0 (light), 2.0-5.0 (medium), 5.0+ (strong)
        let scaledStrength = min(strength * 3.0, MAX_SHAKE_STRENGTH)
        
        print("📊 Shake analysis (samples: \(recentMotionData.count)): max=\(String(format: "%.2f", maxAcceleration)), variance=\(String(format: "%.2f", variance)), mean=\(String(format: "%.2f", mean)), strength=\(String(format: "%.2f", scaledStrength))")
        
        // Clear recent data after calculation to prepare for next shake
        recentMotionData.removeAll()
        
        return scaledStrength
    }
    
    deinit {
        motionManager.stopAccelerometerUpdates()
        backgroundMonitoringTimer?.invalidate()
    }
}

