//
//  AppPerformanceMonitor.swift
//  ClosedCaptioner
//
//  App + device samples. Fast series: 15 min @ 3s. Slow series: 1 h @ 30s.
//

import Combine
import Darwin
import Foundation
import UIKit

final class AppPerformanceMonitor: ObservableObject {
    static let shared = AppPerformanceMonitor()
    static let fastHistoryInterval: TimeInterval = 3
    static let fastHistoryWindow: TimeInterval = 15 * 60
    static let slowHistoryInterval: TimeInterval = 30
    static let slowHistoryWindow: TimeInterval = 60 * 60

    @Published private(set) var memoryBytes: UInt64 = 0
    @Published private(set) var cpuPercent: Double = 0
    @Published private(set) var threadCount: Int = 0
    @Published private(set) var deviceMemoryBytes: UInt64 = 0
    @Published private(set) var deviceCPUPercent: Double = 0
    @Published private(set) var deviceThreadCount: Int = 0
    @Published private(set) var thermalState: ProcessInfo.ThermalState = .nominal
    @Published private(set) var batteryPercent: Int?
    @Published private(set) var isLowPowerMode = false
    @Published private(set) var freeDiskBytes: UInt64 = 0
    @Published private(set) var memoryWarningCount = 0
    @Published private(set) var appUptime: TimeInterval = 0

    @Published private(set) var cpuHistory: [KPIMetricSample] = []
    @Published private(set) var memoryHistory: [KPIMetricSample] = []
    @Published private(set) var threadHistory: [KPIMetricSample] = []
    @Published private(set) var deviceCPUHistory: [KPIMetricSample] = []
    @Published private(set) var deviceMemoryHistory: [KPIMetricSample] = []
    @Published private(set) var deviceThreadHistory: [KPIMetricSample] = []
    @Published private(set) var batteryHistory: [KPIMetricSample] = []
    @Published private(set) var diskHistory: [KPIMetricSample] = []

    private var liveTimer: Timer?
    private var historyTimer: Timer?
    private var lastFastHistoryAt: Date?
    private var lastSlowHistoryAt: Date?
    private var previousHostTicks: (user: natural_t, system: natural_t, idle: natural_t, nice: natural_t)?
    private var hasDeviceCPUSample = false
    private var memoryWarningObserver: NSObjectProtocol?
    private let processStart = Date()

    private init() {}

    deinit {
        liveTimer?.invalidate()
        historyTimer?.invalidate()
    }

    /// Fast 3s history plus slow 30s series. Safe at launch; no-ops if already running.
    func startHistory() {
        guard historyTimer == nil else { return }
        enableMonitoring()
        sample(recordFast: true, recordSlow: true)
        let timer = Timer(timeInterval: Self.fastHistoryInterval, repeats: true) { [weak self] _ in
            self?.sampleFromHistoryTimer()
        }
        RunLoop.main.add(timer, forMode: .common)
        historyTimer = timer
    }

    /// 1s live values while the KPIs tab is visible.
    func start() {
        startHistory()
        guard liveTimer == nil else { return }
        sample(recordFast: false, recordSlow: false)
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.sample(recordFast: false, recordSlow: false)
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
    var formattedThreads: String { "\(threadCount)" }
    var formattedDeviceMemory: String { Self.formatBytes(deviceMemoryBytes) }
    var formattedDeviceCPU: String {
        hasDeviceCPUSample ? String(format: "%.0f%%", deviceCPUPercent) : "…"
    }
    var formattedDeviceThreads: String { "\(deviceThreadCount)" }
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

    private func sampleFromHistoryTimer() {
        let now = Date()
        let recordSlow = lastSlowHistoryAt == nil
            || now.timeIntervalSince(lastSlowHistoryAt!) >= Self.slowHistoryInterval - 0.5
        sample(recordFast: true, recordSlow: recordSlow)
    }

    private func sample(recordFast: Bool, recordSlow: Bool) {
        memoryBytes = currentMemoryFootprint()
        let (cpu, threads) = currentCPUAndThreadCount()
        cpuPercent = cpu
        threadCount = threads
        deviceMemoryBytes = currentDeviceMemoryUsed()
        if let deviceCPU = currentDeviceCPUPercent() {
            deviceCPUPercent = deviceCPU
            hasDeviceCPUSample = true
        }
        deviceThreadCount = currentDeviceThreadCount()
        thermalState = ProcessInfo.processInfo.thermalState
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        let level = UIDevice.current.batteryLevel
        batteryPercent = level >= 0 ? Int((level * 100).rounded()) : nil
        freeDiskBytes = currentFreeDisk()
        appUptime = Date().timeIntervalSince(processStart)

        if recordFast || lastFastHistoryAt == nil {
            appendFastHistory()
        }
        if recordSlow || lastSlowHistoryAt == nil {
            appendSlowHistory()
        }
    }

    private func appendFastHistory() {
        let now = Date()
        if let lastFastHistoryAt, now.timeIntervalSince(lastFastHistoryAt) < Self.fastHistoryInterval - 0.5 {
            return
        }
        lastFastHistoryAt = now
        cpuHistory.append(KPIMetricSample(date: now, value: cpuPercent))
        memoryHistory.append(KPIMetricSample(date: now, value: Double(memoryBytes)))
        threadHistory.append(KPIMetricSample(date: now, value: Double(threadCount)))
        if hasDeviceCPUSample {
            deviceCPUHistory.append(KPIMetricSample(date: now, value: deviceCPUPercent))
        }
        deviceMemoryHistory.append(KPIMetricSample(date: now, value: Double(deviceMemoryBytes)))
        deviceThreadHistory.append(KPIMetricSample(date: now, value: Double(deviceThreadCount)))
        trim(&cpuHistory, window: Self.fastHistoryWindow, now: now)
        trim(&memoryHistory, window: Self.fastHistoryWindow, now: now)
        trim(&threadHistory, window: Self.fastHistoryWindow, now: now)
        trim(&deviceCPUHistory, window: Self.fastHistoryWindow, now: now)
        trim(&deviceMemoryHistory, window: Self.fastHistoryWindow, now: now)
        trim(&deviceThreadHistory, window: Self.fastHistoryWindow, now: now)
    }

    private func appendSlowHistory() {
        let now = Date()
        if let lastSlowHistoryAt, now.timeIntervalSince(lastSlowHistoryAt) < Self.slowHistoryInterval - 0.5 {
            return
        }
        lastSlowHistoryAt = now
        diskHistory.append(KPIMetricSample(date: now, value: Double(freeDiskBytes)))
        if let batteryPercent {
            batteryHistory.append(KPIMetricSample(date: now, value: Double(batteryPercent)))
        }
        trim(&diskHistory, window: Self.slowHistoryWindow, now: now)
        trim(&batteryHistory, window: Self.slowHistoryWindow, now: now)
    }

    private func trim(_ history: inout [KPIMetricSample], window: TimeInterval, now: Date) {
        let cutoff = now.addingTimeInterval(-window)
        history.removeAll { $0.date < cutoff }
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

    /// Whole-device CPU from host tick deltas (user+system+nice vs idle).
    private func currentDeviceCPUPercent() -> Double? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        let user = info.cpu_ticks.0
        let system = info.cpu_ticks.1
        let idle = info.cpu_ticks.2
        let nice = info.cpu_ticks.3
        defer { previousHostTicks = (user, system, idle, nice) }
        guard let previous = previousHostTicks else { return nil }
        let dUser = Double(user &- previous.user)
        let dSystem = Double(system &- previous.system)
        let dIdle = Double(idle &- previous.idle)
        let dNice = Double(nice &- previous.nice)
        let total = dUser + dSystem + dIdle + dNice
        guard total > 0 else { return nil }
        return min(100, (dUser + dSystem + dNice) / total * 100)
    }

    /// Occupied device RAM (physical − free − speculative).
    private func currentDeviceMemoryUsed() -> UInt64 {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        let page = UInt64(vm_kernel_page_size)
        let free = (UInt64(stats.free_count) + UInt64(stats.speculative_count)) * page
        let total = ProcessInfo.processInfo.physicalMemory
        return total > free ? total - free : 0
    }

    /// Runnable + waiting threads on the default processor set (device-wide).
    private func currentDeviceThreadCount() -> Int {
        var pset: processor_set_name_t = 0
        guard processor_set_default(mach_host_self(), &pset) == KERN_SUCCESS else { return 0 }
        defer { mach_port_deallocate(mach_task_self_, pset) }
        var info = processor_set_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<processor_set_load_info>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                processor_set_statistics(pset, PROCESSOR_SET_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return Int(info.thread_count)
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
