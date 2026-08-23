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
    @ObservedObject var p2pInbox: P2PInboxService
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
    @ObservedObject var p2pInbox: P2PInboxService
    @ObservedObject private var performance = AppPerformanceMonitor.shared
    @State private var showResetConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    showResetConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(AppType.display(11, weight: .bold))
                        Text("Reset")
                            .font(AppType.display(12, weight: .bold))
                    }
                    .foregroundColor(appState.colors.danger)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(appState.colors.card)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(appState.colors.danger.opacity(0.7), lineWidth: 1)
                    )
                }
                .accessibilityLabel("Reset all KPIs")

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    kpiSection("Performance") {
                        kpiRow("CPU", performance.formattedCPU)
                        kpiRow("Peak CPU", performance.formattedPeakCPU)
                        kpiRow("Memory", performance.formattedMemory)
                        kpiRow("Peak memory", performance.formattedPeakMemory)
                        kpiRow("Threads", "\(performance.threadCount)")
                        kpiRow("Thermal", performance.formattedThermal)
                        kpiRow("Battery", performance.formattedBattery)
                        kpiRow("Low Power", performance.isLowPowerMode ? "On" : "Off")
                        kpiRow("Disk free", performance.formattedDisk)
                        kpiRow("Memory warnings", "\(performance.memoryWarningCount)")
                        kpiRow("App uptime", performance.formattedUptime)
                    }

                    kpiSection("Radio") {
                        kpiRow("Status", p2pInbox.isListening ? "On" : "Off")
                        kpiRow("Relay", appState.relayMessages ? "On" : "Off")
                        kpiRow("Peers", "\(p2pInbox.connectedPeerCount)")
                        kpiRow("Peak peers", "\(p2pInbox.peakPeerCount)")
                        kpiRow("Connects", "\(p2pInbox.connectCount)")
                        kpiRow("Disconnects", "\(p2pInbox.disconnectCount)")
                        kpiRow("Invite timeouts", "\(p2pInbox.inviteTimeouts)")
                    }

                    kpiSection("Traffic") {
                        kpiRow("Messages sent", "\(p2pInbox.messagesSent)")
                        kpiRow("Messages received", "\(p2pInbox.messagesReceived)")
                        kpiRow("Bytes sent", compactBytes(p2pInbox.bytesSent))
                        kpiRow("Bytes received", compactBytes(p2pInbox.bytesReceived))
                    }

                    kpiSection("Relay") {
                        kpiRow("Forwarded", "\(p2pInbox.messagesForwarded)")
                        kpiRow("Duplicates dropped", "\(p2pInbox.duplicatesDropped)")
                        kpiRow("TTL dropped", "\(p2pInbox.ttlDropped)")
                        kpiRow("Last hop", "\(p2pInbox.lastHop)")
                    }

                    kpiSection("Log") {
                        kpiRow("Buffer", "\(p2pInbox.messages.count)/\(P2PConfig.maxLogCount)")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(appState.colors.background)
        .alert("Reset KPIs?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                p2pInbox.resetKPIs()
                performance.resetPeaks()
            }
        } message: {
            Text("This zeros radio counters and performance peaks. The message log is not cleared.")
        }
        .onAppear { performance.start() }
        .onDisappear { performance.stop() }
    }

    private func kpiSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppType.display(22))
                .tracking(-0.6)
                .foregroundColor(appState.colors.text)
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
    @ObservedObject var p2pInbox: P2PInboxService

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm:ss a"
        return formatter
    }()

    var body: some View {
        Group {
            if p2pInbox.messages.isEmpty {
                VStack {
                    Spacer()
                    Text("No nearby messages yet")
                        .font(AppType.display(22))
                        .tracking(-0.6)
                        .foregroundColor(appState.colors.muted)
                    Text("Turn the radio on to collect the live 200-message buffer.")
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
                            ForEach(p2pInbox.messages) { entry in
                                logRow(entry)
                                    .id(entry.id)
                            }
                        }
                        .padding(20)
                    }
                    .onAppear {
                        scrollToEnd(proxy)
                    }
                    .onChange(of: p2pInbox.messages.last?.id) { _ in
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
        guard let lastID = p2pInbox.messages.last?.id else { return }
        DispatchQueue.main.async {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }
}
