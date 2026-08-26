//
//  ControlsView.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

/// Top bar → top banner → captions (behind spacer) → nearby log → bottom banner → bottom bar.
/// One VStack so banners cannot overlay the control buttons.
struct ControlsView: View {
    @ObservedObject var micController: MicController
    @ObservedObject var appState: AppStateViewModel
    let p2pInbox: P2PInboxService
    @ObservedObject private var premiumManager = PremiumManager.shared
    let onClear: () -> Void

    private var showBanners: Bool {
        !premiumManager.isPremium
            && premiumManager.adsStarted
            && !appState.showSettings
            && !appState.showKeyboard
    }

    var body: some View {
        VStack(spacing: 0) {
            RadioTopBar(appState: appState, inbox: p2pInbox)
                .padding(.vertical, 10)
                .background(appState.colors.background)
                .layoutPriority(1)

            if showBanners {
                BannerAdView(adUnitID: AdConfig.topBannerAdUnitID)
                    .padding(.top, 4)
                    .layoutPriority(1)
            }

            Spacer(minLength: 0)
                .allowsHitTesting(false)

            NearbyLogStrip(appState: appState, inbox: p2pInbox)
                .layoutPriority(1)
                .zIndex(9)

            if showBanners {
                BannerAdView(adUnitID: AdConfig.bottomBannerAdUnitID)
                    .padding(.bottom, 4)
                    .layoutPriority(1)
            }

            bottomBar
                .padding(.vertical, 8)
                .background(appState.colors.background)
                .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(2)
    }

    private var bottomBar: some View {
        HStack {
            Button(action: {
                appState.toggleKeyboard()
            }) {
                Image(systemName: "keyboard")
                    .font(AppType.display(18, weight: .semibold))
                    .foregroundColor(appState.colors.text)
                    .appChromeButton(for: appState.colors)
            }
            .accessibilityLabel("Keyboard")

            Spacer()

            Image(systemName: micController.isRecording ? "stop.fill" : "mic.fill")
                .font(AppType.display(22, weight: .bold))
                .foregroundColor(
                    micController.isRecording
                        ? .white
                        : appState.colors.onAccentFill
                )
                .frame(width: 64, height: 64)
                .background(
                    micController.isRecording
                        ? appState.colors.danger
                        : appState.colors.accentFill
                )
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(appState.colors.line.opacity(micController.isRecording ? 0 : 1), lineWidth: 1)
                )
                .shadow(
                    color: appState.colors.cardShadow,
                    radius: micController.isRecording ? 0 : 12,
                    y: 6
                )
                .contentShape(Circle())
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { _ in
                }, perform: {
                    if micController.isRecording {
                        micController.stopRecording()
                    } else {
                        micController.startRecording()
                    }
                })
                .accessibilityLabel(micController.isRecording ? "Stop recording" : "Start recording")

            Spacer()

            Button(action: onClear) {
                Image(systemName: "eraser.fill")
                    .font(AppType.display(18, weight: .semibold))
                    .foregroundColor(appState.colors.text)
                    .appChromeButton(for: appState.colors)
            }
            .accessibilityLabel("Clear")
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }
}

/// Settings gear, HUD rates, and radio toggle. Observes chrome + traffic, not the log or KPIs.
private struct RadioTopBar: View {
    @ObservedObject var appState: AppStateViewModel
    @ObservedObject private var chrome: P2PRadioChrome
    @ObservedObject private var traffic: P2PTrafficRates
    let inbox: P2PInboxService

    init(appState: AppStateViewModel, inbox: P2PInboxService) {
        self.appState = appState
        self.inbox = inbox
        _chrome = ObservedObject(wrappedValue: inbox.chrome)
        _traffic = ObservedObject(wrappedValue: inbox.traffic)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                appState.toggleSettings()
            }) {
                Image(systemName: "gearshape")
                    .font(AppType.display(18, weight: .semibold))
                    .foregroundColor(appState.colors.text)
                    .appChromeButton(for: appState.colors)
            }
            .accessibilityLabel("Settings")

            Spacer()

            P2PRadioStatsView(
                colors: appState.colors,
                isListening: chrome.isListening,
                peers: chrome.connectedPeerCount,
                bytesInPerSecond: traffic.bytesReceivedPerSecond,
                bytesOutPerSecond: traffic.bytesSentPerSecond,
                isRelaying: appState.relayMessages && chrome.isListening,
                onJoin: {
                    if !chrome.isListening {
                        inbox.startListening()
                    }
                }
            )

            Button(action: {
                inbox.toggleListening()
            }) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(AppType.display(18, weight: .semibold))
                    .foregroundColor(
                        chrome.isListening
                            ? appState.colors.onAccentFill
                            : appState.colors.text
                    )
                    .frame(width: 44, height: 44)
                    .background(
                        chrome.isListening
                            ? appState.colors.accentFill
                            : appState.colors.buttonBackground
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                            .stroke(appState.colors.line, lineWidth: 1)
                    )
            }
            .accessibilityLabel(
                chrome.isListening
                    ? "Turn Huddle off"
                    : "Turn Huddle on"
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(chrome.isListening ? "On" : "Off")
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }
}

/// Nearby log strip. Hidden when radio is off. Does not observe traffic rates.
private struct NearbyLogStrip: View {
    @ObservedObject var appState: AppStateViewModel
    @ObservedObject private var chrome: P2PRadioChrome
    @ObservedObject private var log: P2PMessageLog

    init(appState: AppStateViewModel, inbox: P2PInboxService) {
        self.appState = appState
        _chrome = ObservedObject(wrappedValue: inbox.chrome)
        _log = ObservedObject(wrappedValue: inbox.log)
    }

    var body: some View {
        if chrome.isListening {
            P2PMessageLogView(
                colors: appState.colors,
                entries: log.messages,
                currentDisplayName: appState.displayName
            )
        }
    }
}

/// Compact radio status left of the antenna. Off: join CTA. On: reach bars + ↓/↑ B/s.
/// Lifetime counters stay under Settings → KPIs.
private struct P2PRadioStatsView: View {
    let colors: ThemeColors
    let isListening: Bool
    let peers: Int
    let bytesInPerSecond: Int
    let bytesOutPerSecond: Int
    let isRelaying: Bool
    let onJoin: () -> Void

    private var filledBars: Int {
        switch peers {
        case 0: return 0
        case 1: return 1
        case 2, 3: return 2
        case 4, 5: return 3
        default: return 4
        }
    }

    var body: some View {
        Group {
            if isListening {
                onState
            } else {
                Button(action: onJoin) {
                    offState
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Huddle")
        .accessibilityValue(accessibilitySummary)
        .accessibilityHint(isListening ? "" : "Turns Huddle on")
    }

    private var offState: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text("Huddle")
                .font(AppType.display(10, weight: .bold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundColor(colors.muted)
            Text("Tap to join")
                .font(AppType.display(13, weight: .semibold))
                .foregroundColor(colors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var onState: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("Huddle")
                .font(AppType.display(10, weight: .bold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundColor(colors.muted)

            HStack(alignment: .center, spacing: 5) {
                reachBars(filled: filledBars)
                VStack(alignment: .trailing, spacing: 2) {
                    rateLabel(direction: "arrow.down", bytesPerSecond: bytesInPerSecond)
                    rateLabel(direction: "arrow.up", bytesPerSecond: bytesOutPerSecond)
                }
            }
        }
    }

    private func rateLabel(direction: String, bytesPerSecond: Int) -> some View {
        HStack(spacing: 3) {
            Image(systemName: direction)
                .font(AppType.display(7, weight: .bold))
                .foregroundColor(colors.accent)
            Text(compactRate(bytesPerSecond))
                .font(AppType.display(8, weight: .semibold))
                .monospacedDigit()
                .foregroundColor(colors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    /// One bar cluster tall enough to sit beside both ↓/↑ rows (~20% smaller).
    private func reachBars(filled: Int) -> some View {
        HStack(alignment: .bottom, spacing: 1.5) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 0.8, style: .continuous)
                    .fill(index < filled ? colors.accent : colors.line)
                    .frame(width: 2.4, height: CGFloat(6 + index * 3))
            }
        }
        .frame(height: 22)
        .accessibilityHidden(true)
    }

    private func compactRate(_ bytesPerSecond: Int) -> String {
        if bytesPerSecond < 1000 { return "\(bytesPerSecond) B/s" }
        if bytesPerSecond < 1_000_000 {
            let k = Double(bytesPerSecond) / 1000.0
            return String(format: k >= 10 ? "%.0fk B/s" : "%.1fk B/s", k)
        }
        let m = Double(bytesPerSecond) / 1_000_000.0
        return String(format: m >= 10 ? "%.0fM B/s" : "%.1fM B/s", m)
    }

    private var accessibilitySummary: String {
        guard isListening else { return "Off, tap to join" }
        var summary = peers == 0
            ? "Looking for peers"
            : "\(peers) connected, reach \(filledBars) of 4"
        summary += ", \(compactRate(bytesInPerSecond)) down, \(compactRate(bytesOutPerSecond)) up"
        if isRelaying {
            summary += ", relaying"
        }
        return summary
    }
}
