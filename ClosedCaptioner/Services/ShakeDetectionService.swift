//
//  ShakeDetectionService.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Foundation
import CoreMotion

/// Service that monitors device motion and calculates shake strength.
/// Sampling runs on a background queue and only while `startMonitoring()` is active.
class ShakeDetectionService: ObservableObject {
    /// Shared singleton instance
    static let shared = ShakeDetectionService()
    
    private let motionManager = CMMotionManager()
    private let motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "ShakeDetection"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        return queue
    }()
    private let dataLock = NSLock()
    /// Recent motion data samples within the history window
    private var recentMotionData: [(acceleration: Double, timestamp: TimeInterval)] = []
    /// Time window for keeping motion data (300ms)
    private let motionHistoryWindow: TimeInterval = 0.3
    /// Maximum shake strength value for normalization
    private let MAX_SHAKE_STRENGTH: Double = 10.0
    private var isMonitoring = false
    
    private init() {
        setupMotionManager()
    }
    
    /// Configures the motion manager for accelerometer monitoring
    private func setupMotionManager() {
        guard motionManager.isAccelerometerAvailable else {
            AppLog.debug("[ShakeDetectionService] WARNING: Accelerometer not available")
            return
        }
        
        motionManager.accelerometerUpdateInterval = 0.03 // ~33Hz (30ms updates)
    }
    
    /// Starts accelerometer sampling on a background queue. No-op if already running.
    func startMonitoring() {
        guard !isMonitoring else { return }
        guard motionManager.isAccelerometerAvailable else { return }
        isMonitoring = true
        
        motionManager.startAccelerometerUpdates(to: motionQueue) { [weak self] (data, error) in
            if let error = error {
                AppLog.debug("[ShakeDetectionService] ERROR: Accelerometer update error: \(error.localizedDescription)")
                return
            }
            guard let self = self, let data = data else { return }
            
            let timestamp = data.timestamp
            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z
            
            let magnitude = sqrt(x*x + y*y + z*z)
            let userAcceleration = abs(magnitude - 1.0)
            
            self.dataLock.lock()
            self.recentMotionData.append((acceleration: userAcceleration, timestamp: timestamp))
            let cutoffTime = timestamp - self.motionHistoryWindow
            self.recentMotionData.removeAll { $0.timestamp < cutoffTime }
            self.dataLock.unlock()
        }
    }
    
    /// Stops accelerometer sampling. Safe to call when already stopped.
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        motionManager.stopAccelerometerUpdates()
        dataLock.lock()
        recentMotionData.removeAll()
        dataLock.unlock()
    }
    
    /// Calculates shake strength from recent motion data
    /// Uses a combination of max acceleration, variance, and mean to determine intensity
    /// - Returns: A normalized shake strength value (0.0 to MAX_SHAKE_STRENGTH)
    /// - Note: Clears recent motion data after calculation
    func getShakeStrength() -> Double {
        dataLock.lock()
        defer { dataLock.unlock() }
        
        guard !recentMotionData.isEmpty else {
            return 0.0
        }
        
        let accelerations = recentMotionData.map { $0.acceleration }
        
        let mean = accelerations.reduce(0, +) / Double(accelerations.count)
        let maxAcceleration = accelerations.max() ?? 0.0
        let variance = accelerations.map { pow($0 - mean, 2) }.reduce(0, +) / Double(accelerations.count)
        
        let strength = (maxAcceleration * 0.5) + (sqrt(variance) * 0.3) + (mean * 0.2)
        let scaledStrength = min(strength * 3.0, MAX_SHAKE_STRENGTH)
        
        if scaledStrength > 0.5 {
            AppLog.debug("[ShakeDetectionService] Shake analysis (samples: \(recentMotionData.count)): max=\(String(format: "%.2f", maxAcceleration)), variance=\(String(format: "%.2f", variance)), mean=\(String(format: "%.2f", mean)), strength=\(String(format: "%.2f", scaledStrength))")
        }
        
        recentMotionData.removeAll()
        
        return scaledStrength
    }
    
    deinit {
        motionManager.stopAccelerometerUpdates()
    }
}
