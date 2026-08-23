//
//  AppPerformanceMonitor.swift
//  ClosedCaptioner
//
//  Live process samples plus a rolling 1-hour history (one point every 30s).
//

import Combine
import Darwin
import Foundation
import UIKit

final class AppPerformanceMonitor: ObservableObject {
    static let shared = AppPerformanceMonitor()
    static let historyInterval: TimeInterval = 30
    static let historyWindow: TimeInterval = 60 * 60

    @Published private(set) var memoryBytes: UInt64 = 0
    @Published private(set) var cpuPercent: Double = 0
    @Published private(set) var threadCount: Int = 0
    @Published private(set) var thermalState: ProcessInfo.ThermalState = .nominal
    @Published private(set) var batteryPercent: Int?
    @Published private(set) var isLowPowerMode = false
    @Published private(set) var freeDiskBytes: UInt64 = 0
    @Published private(set) var memoryWarningCount = 0
    @Published private(set) var appUptime: TimeInterval = 0

    @Published private(set) var cpuHistory: [KPIMetricSample] = []
    @Published private(set) var memoryHistory: [KPIMetricSample] = []
    @Published private(set) var threadHistory: [KPIMetricSample] = []
    @Published private(set) var batteryHistory: [KPIMetricSample] = []
    @Published private(set) var diskHistory: [KPIMetricSample] = []

    private var liveTimer: Timer?
    private var historyTimer: Timer?
    private var lastHistoryAt: Date?
    private var memoryWarningObserver: NSObjectProtocol?
    private let processStart = Date()

    private init() {}

    deinit {
        liveTimer?.invalidate()
        historyTimer?.invalidate()
    }

    /// Rolling 30s history. Safe to call at launch; no-ops if already running.
    func startHistory() {
        guard historyTimer == nil else { return }
        enableMonitoring()
        sample(recordHistory: true)
        let timer = Timer(timeInterval: Self.historyInterval, repeats: true) { [weak self] _ in
            self?.sample(recordHistory: true)
        }
        RunLoop.main.add(timer, forMode: .common)
        historyTimer = timer
    }

    /// 1s live values while the KPIs tab is visible.
    func start() {
        startHistory()
        guard liveTimer == nil else { return }
        sample(recordHistory: false)
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.sample(recordHistory: false)
        }
        RunLoop.main.add(timer, forMode: .common)
        liveTimer = timer
    }

    func stop() {
        liveTimer?.invalidate()
        liveTimer = nil
    }

    var formattedMemory: String { Self.formatBytes(memoryBytes) }
    var formattedCPU: String { String(format: "%.0f%%", cpuPercent) }
    var formattedThermal: String {
        switch thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
    var formattedBattery: String {
        guard let batteryPercent else { return "n/a" }
        return "\(batteryPercent)%"
    }
    var formattedDisk: String { Self.formatBytes(freeDiskBytes) }
    var formattedUptime: String { formatUptime(appUptime) }
    var formattedThreads: String { "\(threadCount)" }

    static func formatBytes(_ bytes: UInt64) -> String {
        let n = Double(bytes)
        if n < 1000 { return "\(bytes)B" }
        if n < 1_000_000 { return String(format: "%.1f kB", n / 1000) }
        if n < 1_000_000_000 { return String(format: "%.1f MB", n / 1_000_000) }
        return String(format: "%.2f GB", n / 1_000_000_000)
    }

    static func formatBytes(_ bytes: Double) -> String {
        formatBytes(UInt64(max(0, bytes.rounded())))
    }

    private func enableMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        if memoryWarningObserver == nil {
            memoryWarningObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.didReceiveMemoryWarningNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.memoryWarningCount += 1
            }
        }
    }

    private func sample(recordHistory: Bool) {
        memoryBytes = currentMemoryFootprint()
        let (cpu, threads) = currentCPUAndThreadCount()
        cpuPercent = cpu
        threadCount = threads
        thermalState = ProcessInfo.processInfo.thermalState
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        let level = UIDevice.current.batteryLevel
        batteryPercent = level >= 0 ? Int((level * 100).rounded()) : nil
        freeDiskBytes = currentFreeDisk()
        appUptime = Date().timeIntervalSince(processStart)

        if recordHistory {
            appendHistory()
        } else if lastHistoryAt == nil {
            appendHistory()
        }
    }

    private func appendHistory() {
        let now = Date()
        if let lastHistoryAt, now.timeIntervalSince(lastHistoryAt) < Self.historyInterval - 0.5 {
            return
        }
        lastHistoryAt = now
        cpuHistory.append(KPIMetricSample(date: now, value: cpuPercent))
        memoryHistory.append(KPIMetricSample(date: now, value: Double(memoryBytes)))
        threadHistory.append(KPIMetricSample(date: now, value: Double(threadCount)))
        diskHistory.append(KPIMetricSample(date: now, value: Double(freeDiskBytes)))
        if let batteryPercent {
            batteryHistory.append(KPIMetricSample(date: now, value: Double(batteryPercent)))
        }
        trimHistory(now: now)
    }

    private func trimHistory(now: Date) {
        let cutoff = now.addingTimeInterval(-Self.historyWindow)
        cpuHistory.removeAll { $0.date < cutoff }
        memoryHistory.removeAll { $0.date < cutoff }
        threadHistory.removeAll { $0.date < cutoff }
        batteryHistory.removeAll { $0.date < cutoff }
        diskHistory.removeAll { $0.date < cutoff }
    }

    private func currentMemoryFootprint() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return info.phys_footprint
    }

    /// One `task_threads` pass for CPU and count. Each port is deallocated;
    /// the array is `vm_deallocate`d in `defer`.
    private func currentCPUAndThreadCount() -> (cpu: Double, threads: Int) {
        var threadList: thread_act_array_t?
        var count: mach_msg_type_number_t = 0
        guard task_threads(mach_task_self_, &threadList, &count) == KERN_SUCCESS,
              let threads = threadList else {
            return (0, 0)
        }
        defer {
            let size = vm_size_t(MemoryLayout<thread_t>.stride * Int(count))
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threads)), size)
        }

        var total: Double = 0
        for index in 0..<Int(count) {
            var info = thread_basic_info()
            var infoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
            let status = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) {
                    thread_info(threads[index], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
                }
            }
            mach_port_deallocate(mach_task_self_, threads[index])
            guard status == KERN_SUCCESS else { continue }
            guard info.flags & TH_FLAGS_IDLE == 0 else { continue }
            total += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100
        }
        let cpu = min(total, 100 * Double(ProcessInfo.processInfo.activeProcessorCount))
        return (cpu, Int(count))
    }

    private func currentFreeDisk() -> UInt64 {
        let path = NSHomeDirectory()
        let values = try? URL(fileURLWithPath: path).resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        if let important = values?.volumeAvailableCapacityForImportantUsage, important > 0 {
            return UInt64(important)
        }
        return 0
    }

    private func formatUptime(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        }
        if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        }
        return String(format: "%ds", seconds)
    }
}
