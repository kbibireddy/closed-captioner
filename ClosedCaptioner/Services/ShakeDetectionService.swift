//
//  ShakeDetectionService.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Foundation
import CoreMotion

/// Service that continuously monitors device motion and calculates shake strength
/// Uses accelerometer data to detect and quantify shake gestures
class ShakeDetectionService: ObservableObject {
    /// Shared singleton instance
    static let shared = ShakeDetectionService()
    
    private let motionManager = CMMotionManager()
    /// Recent motion data samples within the history window
    private var recentMotionData: [(acceleration: Double, timestamp: TimeInterval)] = []
    /// Time window for keeping motion data (300ms)
    private let motionHistoryWindow: TimeInterval = 0.3
    private var backgroundMonitoringTimer: Timer?
    /// Maximum shake strength value for normalization
    private let MAX_SHAKE_STRENGTH: Double = 10.0
    
    private init() {
        setupMotionManager()
        startBackgroundMonitoring()
    }
    
    /// Configures the motion manager for accelerometer monitoring
    private func setupMotionManager() {
        guard motionManager.isAccelerometerAvailable else {
            print("[ShakeDetectionService] WARNING: Accelerometer not available")
            return
        }
        
        // Use a moderate update interval for background monitoring
        motionManager.accelerometerUpdateInterval = 0.03 // ~33Hz (30ms updates)
    }
    
    /// Starts continuous background monitoring of accelerometer data
    /// Collects motion data within the history window for shake strength calculation
    private func startBackgroundMonitoring() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        // Continuously monitor accelerometer in the background at low frequency
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            if let error = error {
                print("[ShakeDetectionService] ERROR: Accelerometer update error: \(error.localizedDescription)")
                return
            }
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
    
    /// Calculates shake strength from recent motion data
    /// Uses a combination of max acceleration, variance, and mean to determine intensity
    /// - Returns: A normalized shake strength value (0.0 to MAX_SHAKE_STRENGTH)
    /// - Note: Clears recent motion data after calculation
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
        
        // Debug logging (can be removed in production)
        if scaledStrength > 0.5 {
            print("[ShakeDetectionService] Shake analysis (samples: \(recentMotionData.count)): max=\(String(format: "%.2f", maxAcceleration)), variance=\(String(format: "%.2f", variance)), mean=\(String(format: "%.2f", mean)), strength=\(String(format: "%.2f", scaledStrength))")
        }
        
        // Clear recent data after calculation to prepare for next shake
        recentMotionData.removeAll()
        
        return scaledStrength
    }
    
    /// Cleans up motion manager and timers on deallocation
    deinit {
        motionManager.stopAccelerometerUpdates()
        backgroundMonitoringTimer?.invalidate()
        backgroundMonitoringTimer = nil
    }
}

