//
//  SettingsView.swift
//  ClosedCaptioner
//

import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case kpis
    case history
    case logs
    case purchases

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "Preferences"
        case .kpis: return "KPIs"
        case .history: return "History"
        case .logs: return "Logs"
        case .purchases: return "Purchases"
        }
    }

    var systemImage: String {
        switch self {
        case .general: return "slider.horizontal.3"
        case .kpis: return "chart.bar"
        case .history: return "clock"
        case .logs: return "text.alignleft"
        case .purchases: return "cart"
        }
    }

    var selectedSystemImage: String {
        switch self {
        case .general: return "slider.horizontal.3"
        case .kpis: return "chart.bar.fill"
        case .history: return "clock.fill"
        case .logs: return "text.alignleft"
        case .purchases: return "cart.fill"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var appState: AppStateViewModel
    @ObservedObject var historyManager: HistoryManager
    let p2pInbox: P2PInboxService
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        let _ = appState.fontChoice
        ZStack {
            appState.colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Group {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsView(appState: appState)
                    case .kpis:
                        KPISettingsView(appState: appState, p2pInbox: p2pInbox)
                    case .history:
                        HistoryContentView(
                            appState: appState,
                            historyManager: historyManager
                        )
                    case .logs:
                        P2PLogsSettingsView(appState: appState, p2pInbox: p2pInbox)
                    case .purchases:
                        PurchasesView(appState: appState)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                settingsTabBar
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Settings")
                .font(AppType.display(28))
                .tracking(-1.0)
                .foregroundColor(appState.colors.text)

            Spacer()

            DoneButton(
                appState: appState,
                text: "Done",
                onAction: {
                    let wasOnHistory = selectedTab == .history
                    appState.closeSettings()
                    guard wasOnHistory, !PremiumManager.shared.isPremium else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        InterstitialCoordinator.shared.presentAfterHistoryClose()
                    }
                }
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var settingsTabBar: some View {
        HStack(spacing: 3) {
            ForEach(SettingsTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: selectedTab == tab ? tab.selectedSystemImage : tab.systemImage)
                            .font(AppType.display(14, weight: .bold))
                        Text(tab.title)
                            .font(AppType.display(9, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundColor(
                        selectedTab == tab
                            ? appState.colors.onAccent
                            : appState.colors.muted
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab
                            ? appState.colors.accent
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(5)
        .background(appState.colors.buttonBackground)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(appState.colors.line, lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }
}

struct KPISettingsView: View {
    @ObservedObject var appState: AppStateViewModel
    let p2pInbox: P2PInboxService
    @ObservedObject private var chrome: P2PRadioChrome
    @ObservedObject private var metrics: P2PRadioMetrics
    @ObservedObject private var log: P2PMessageLog
    @ObservedObject private var performance = AppPerformanceMonitor.shared

    init(appState: AppStateViewModel, p2pInbox: P2PInboxService) {
        self.appState = appState
        self.p2pInbox = p2pInbox
        _chrome = ObservedObject(wrappedValue: p2pInbox.chrome)
        _metrics = ObservedObject(wrappedValue: p2pInbox.metrics)
        _log = ObservedObject(wrappedValue: p2pInbox.log)
    }

    private let cardColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Performance")
                        .font(AppType.display(22))
                        .tracking(-0.6)
                        .foregroundColor(appState.colors.text)

                    LazyVGrid(columns: cardColumns, spacing: 10) {
                        KPIMetricCard(
                            title: "App CPU",
                            valueText: performance.formattedCPU,
                            samples: performance.cpuHistory,
                            colors: appState.colors,
                            window: AppPerformanceMonitor.fastHistoryWindow,
                            yScale: .zeroToAtLeast(100),
                            formatY: { String(format: "%.0f%%", $0) }
                        )
                        KPIMetricCard(
                            title: "CPU",
                            valueText: performance.formattedDeviceCPU,
                            samples: performance.deviceCPUHistory,
                            colors: appState.colors,
                            window: AppPerformanceMonitor.fastHistoryWindow,
                            yScale: .zeroToAtLeast(100),
                            formatY: { String(format: "%.0f%%", $0) }
                        )
                        KPIMetricCard(
                            title: "App Memory",
                            valueText: performance.formattedMemory,
                            samples: performance.memoryHistory,
                            colors: appState.colors,
                            window: AppPerformanceMonitor.fastHistoryWindow,
                            yScale: .padded,
                            formatY: { AppPerformanceMonitor.formatBytes($0) }
                        )
                        KPIMetricCard(
                            title: "Memory",
                            valueText: performance.formattedDeviceMemory,
                            samples: performance.deviceMemoryHistory,
                            colors: appState.colors,
                            window: AppPerformanceMonitor.fastHistoryWindow,
                            yScale: .padded,
                            formatY: { AppPerformanceMonitor.formatBytes($0) }
                        )
                        KPIMetricCard(
                            title: "App Threads",
                            valueText: performance.formattedThreads,
                            samples: performance.threadHistory,
                            colors: appState.colors,
                            window: AppPerformanceMonitor.fastHistoryWindow,
                            yScale: .zeroToAtLeast(8),
                            formatY: { String(format: "%.0f", $0) }
                        )
                        KPIMetricCard(
                            title: "Threads",
                            valueText: performance.formattedDeviceThreads,
                            samples: performance.deviceThreadHistory,
                            colors: appState.colors,
                            window: AppPerformanceMonitor.fastHistoryWindow,
                            yScale: .zeroToAtLeast(8),
                            formatY: { String(format: "%.0f", $0) }
                        )
                        KPIMetricCard(
                            title: "Battery",
                            valueText: performance.formattedBattery,
                            samples: performance.batteryHistory,
                            colors: appState.colors,
                            window: AppPerformanceMonitor.slowHistoryWindow,
                            yScale: .zeroToHundred,
                            formatY: { String(format: "%.0f%%", $0) }
                        )
                        KPIMetricCard(
                            title: "Disk free",
                            valueText: performance.formattedDisk,
                            samples: performance.diskHistory,
                            colors: appState.colors,
                            window: AppPerformanceMonitor.slowHistoryWindow,
                            yScale: .padded,
                            formatY: { AppPerformanceMonitor.formatBytes($0) }
                        )
                    }
                }

                kpiTable {
                    kpiRow("Thermal", performance.formattedThermal)
                    kpiRow("Low Power", performance.isLowPowerMode ? "On" : "Off")
                    kpiRow("Memory warnings", "\(performance.memoryWarningCount)")
                    kpiRow("App uptime", performance.formattedUptime)
                }

                kpiSection("Huddle", table: {
                    kpiRow("Status", chrome.isListening ? "On" : "Off")
                    kpiRow("Relay", (chrome.isListening && appState.relayMessages) ? "On" : "Off")
                }, cards: {
                    KPIMetricCard(
                        title: "Peers",
                        valueText: "\(chrome.connectedPeerCount)",
                        samples: metrics.peerHistory,
                        colors: appState.colors,
                        window: AppPerformanceMonitor.fastHistoryWindow,
                        yScale: .zeroToAtLeast(1),
                        formatY: formatCount
                    )
                    KPIMetricCard(
                        title: "Connects",
                        valueText: "\(metrics.connectCount)",
                        samples: metrics.connectHistory,
                        colors: appState.colors,
                        window: AppPerformanceMonitor.slowHistoryWindow,
                        yScale: .zeroToAtLeast(1),
                        formatY: formatCount
                    )
                    KPIMetricCard(
                        title: "Disconnects",
                        valueText: "\(metrics.disconnectCount)",
                        samples: metrics.disconnectHistory,
                        colors: appState.colors,
                        window: AppPerformanceMonitor.slowHistoryWindow,
                        yScale: .zeroToAtLeast(1),
                        formatY: formatCount
                    )
                    KPIMetricCard(
                        title: "Invite timeouts",
                        valueText: "\(metrics.inviteTimeouts)",
                        samples: metrics.inviteTimeoutHistory,
                        colors: appState.colors,
                        window: AppPerformanceMonitor.slowHistoryWindow,
                        yScale: .zeroToAtLeast(1),
                        formatY: formatCount
                    )
                })

                kpiCardSection("Traffic", cards: {
                    KPIMetricCard(
                        title: "Messages sent",
                        valueText: "\(metrics.messagesSent)",
                        samples: metrics.messagesSentHistory,
                        colors: appState.colors,
                        window: AppPerformanceMonitor.fastHistoryWindow,
                        yScale: .zeroToAtLeast(1),
                        formatY: formatCount
                    )
                    KPIMetricCard(
                        title: "Messages received",
                        valueText: "\(metrics.messagesReceived)",
                        samples: metrics.messagesReceivedHistory,
                        colors: appState.colors,
                        window: AppPerformanceMonitor.fastHistoryWindow,
                        yScale: .zeroToAtLeast(1),
                        formatY: formatCount
                    )
                    KPIMetricCard(
                        title: "Bytes sent",
                        valueText: compactBytes(metrics.bytesSent),
                        samples: metrics.bytesSentHistory,
                        colors: appState.colors,
                        window: AppPerformanceMonitor.fastHistoryWindow,
                        yScale: .padded,
                        formatY: { compactBytes(Int($0.rounded())) }
                    )
                    KPIMetricCard(
                        title: "Bytes received",
                        valueText: compactBytes(metrics.bytesReceived),
                        samples: metrics.bytesReceivedHistory,
                        colors: appState.colors,
                        window: AppPerformanceMonitor.fastHistoryWindow,
                        yScale: .padded,
                        formatY: { compactBytes(Int($0.rounded())) }
                    )
                })

                kpiSection("Relay") {
                    kpiRow("Forwarded", "\(metrics.messagesForwarded)")
                    kpiRow("Duplicates dropped", "\(metrics.duplicatesDropped)")
                    kpiRow("TTL dropped", "\(metrics.ttlDropped)")
                    kpiRow("Last hop", "\(metrics.lastHop)")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Message Log")
                        .font(AppType.display(22))
                        .tracking(-0.6)
                        .foregroundColor(appState.colors.text)

                    Button {
                        p2pInbox.clearLog()
                    } label: {
                        Text("Clear log")
                            .font(AppType.display(13, weight: .bold))
                            .foregroundColor(appState.colors.danger)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(appState.colors.card)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(appState.colors.danger.opacity(0.55), lineWidth: 1)
                            )
                    }
                    .disabled(log.messages.isEmpty)
                    .opacity(log.messages.isEmpty ? 0.45 : 1)
                    .accessibilityLabel("Clear message log")

                    kpiTable {
                        kpiRow("Buffer", "\(log.messages.count)/\(P2PConfig.maxLogCount)")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(appState.colors.background)
        .onAppear {
            performance.start()
            p2pInbox.startKPIHistory()
        }
        .onDisappear { performance.stop() }
    }

    private func kpiSection<Table: View, Cards: View>(
        _ title: String,
        @ViewBuilder table: () -> Table,
        @ViewBuilder cards: () -> Cards
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppType.display(22))
                .tracking(-0.6)
                .foregroundColor(appState.colors.text)
            LazyVGrid(columns: cardColumns, spacing: 10) {
                cards()
            }
            kpiTable(content: table)
        }
    }

    private func kpiCardSection<Cards: View>(
        _ title: String,
        @ViewBuilder cards: () -> Cards
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppType.display(22))
                .tracking(-0.6)
                .foregroundColor(appState.colors.text)
            LazyVGrid(columns: cardColumns, spacing: 10) {
                cards()
            }
        }
    }

    private func kpiSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppType.display(22))
                .tracking(-0.6)
                .foregroundColor(appState.colors.text)
            kpiTable(content: content)
        }
    }

    private var formatCount: (Double) -> String {
        { String(format: "%.0f", $0) }
    }

    private func kpiTable<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(appState.colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(appState.colors.line, lineWidth: 1)
        )
    }

    private func kpiRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(AppType.display(14, weight: .medium))
                .foregroundColor(appState.colors.text)
            Spacer(minLength: 12)
            Text(value)
                .font(AppType.display(14, weight: .bold))
                .monospacedDigit()
                .foregroundColor(appState.colors.muted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func compactBytes(_ n: Int) -> String {
        if n < 1000 { return "\(n)B" }
        if n < 1_000_000 {
            let k = Double(n) / 1000.0
            return String(format: k >= 10 ? "%.0fkB" : "%.1fkB", k)
        }
        let m = Double(n) / 1_000_000.0
        return String(format: m >= 10 ? "%.0fMB" : "%.1fMB", m)
    }
}

struct P2PLogsSettingsView: View {
    @ObservedObject var appState: AppStateViewModel
    @ObservedObject private var log: P2PMessageLog

    init(appState: AppStateViewModel, p2pInbox: P2PInboxService) {
        self.appState = appState
        _log = ObservedObject(wrappedValue: p2pInbox.log)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm:ss a"
        return formatter
    }()

    var body: some View {
        Group {
            if log.messages.isEmpty {
                VStack {
                    Spacer()
                    Text("No nearby messages yet")
                        .font(AppType.display(22))
                        .tracking(-0.6)
                        .foregroundColor(appState.colors.muted)
                    Text("Turn Huddle on to collect the live 200-message buffer.")
                        .font(AppType.display(13, weight: .medium))
                        .foregroundColor(appState.colors.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(log.messages) { entry in
                                logRow(entry)
                                    .id(entry.id)
                            }
                        }
                        .padding(20)
                    }
                    .onAppear {
                        scrollToEnd(proxy)
                    }
                    .onChange(of: log.messages.last?.id) { _ in
                        scrollToEnd(proxy)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appState.colors.background)
        .accessibilityLabel("Nearby message logs")
    }

    private func logRow(_ entry: P2PLogEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.senderName)
                    .font(AppType.display(12, weight: .bold))
                    .foregroundColor(appState.colors.accent)
                Spacer(minLength: 8)
                Text(Self.timeFormatter.string(from: entry.receivedAt))
                    .font(AppType.display(11, weight: .medium))
                    .foregroundColor(appState.colors.muted)
            }
            Text(entry.text)
                .font(AppType.display(16))
                .tracking(-0.4)
                .foregroundColor(appState.colors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(appState.colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(appState.colors.line, lineWidth: 1)
        )
        .accessibilityLabel("\(entry.senderName), \(entry.text)")
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        guard let lastID = log.messages.last?.id else { return }
        DispatchQueue.main.async {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }
}
