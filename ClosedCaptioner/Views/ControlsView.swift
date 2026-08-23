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
    @ObservedObject var p2pInbox: P2PInboxService
    @ObservedObject private var premiumManager = PremiumManager.shared
    let onClear: () -> Void

    private var showBanners: Bool {
        !premiumManager.isPremium
            && !appState.showSettings
            && !appState.showKeyboard
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
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

            if p2pInbox.isListening {
                P2PMessageLogView(
                    colors: appState.colors,
                    entries: p2pInbox.messages
                )
                .layoutPriority(1)
                .zIndex(9)
            }

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

    private var topBar: some View {
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
                isListening: p2pInbox.isListening,
                peers: p2pInbox.connectedPeerCount,
                bytesInPerMinute: p2pInbox.bytesReceivedPerMinute,
                bytesOutPerMinute: p2pInbox.bytesSentPerMinute,
                isRelaying: appState.relayMessages && p2pInbox.isListening,
                onJoin: {
                    if !p2pInbox.isListening {
                        p2pInbox.startListening()
                    }
                }
            )

            Button(action: {
                p2pInbox.toggleListening()
            }) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(AppType.display(18, weight: .semibold))
                    .foregroundColor(
                        p2pInbox.isListening
                            ? appState.colors.onAccentFill
                            : appState.colors.text
                    )
                    .frame(width: 44, height: 44)
                    .background(
                        p2pInbox.isListening
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
                p2pInbox.isListening
                    ? "Turn radio off"
                    : "Turn radio on"
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(p2pInbox.isListening ? "On" : "Off")
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
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

/// Compact radio status left of the antenna. Off: join CTA. On: reach + rolling traffic.
/// Lifetime counters stay under Settings → KPIs.
private struct P2PRadioStatsView: View {
    let colors: ThemeColors
    let isListening: Bool
    let peers: Int
    let bytesInPerMinute: Int
    let bytesOutPerMinute: Int
    let isRelaying: Bool
    let onJoin: () -> Void

    private var reachLevel: (bars: Int, label: String) {
        switch peers {
        case 0: return (0, "Looking…")
        case 1: return (1, "Thin")
        case 2, 3: return (2, "Fair")
        case 4, 5: return (3, "Strong")
        default: return (4, "Full")
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
        .accessibilityLabel("Radio")
        .accessibilityValue(accessibilitySummary)
        .accessibilityHint(isListening ? "" : "Turns radio on")
    }

    private var offState: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text("Radio")
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
        let reach = reachLevel
        return VStack(alignment: .trailing, spacing: 2) {
            Text("Radio")
                .font(AppType.display(10, weight: .bold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundColor(colors.muted)

            if peers == 0 {
                Text("Looking…")
                    .font(AppType.display(13, weight: .semibold))
                    .foregroundColor(colors.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                HStack(alignment: .center, spacing: 6) {
                    reachBars(filled: reach.bars)
                    Text(reach.label)
                        .font(AppType.display(13, weight: .semibold))
                        .foregroundColor(colors.text)
                }
            }

            Text(trafficLine)
                .font(AppType.display(10, weight: .medium))
                .monospacedDigit()
                .foregroundColor(colors.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private func reachBars(filled: Int) -> some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(index < filled ? colors.accent : colors.line)
                    .frame(width: 3, height: CGFloat(6 + index * 3))
            }
        }
        .frame(height: 15)
        .accessibilityHidden(true)
    }

    private var trafficLine: String {
        "↓\(compactRate(bytesInPerMinute)) ↑\(compactRate(bytesOutPerMinute))/m"
    }

    private func compactRate(_ bytesPerMinute: Int) -> String {
        if bytesPerMinute < 1000 { return "\(bytesPerMinute)B" }
        if bytesPerMinute < 1_000_000 {
            let k = Double(bytesPerMinute) / 1000.0
            return String(format: k >= 10 ? "%.0fk" : "%.1fk", k)
        }
        let m = Double(bytesPerMinute) / 1_000_000.0
        return String(format: m >= 10 ? "%.0fM" : "%.1fM", m)
    }

    private var accessibilitySummary: String {
        guard isListening else { return "Off, tap to join" }
        var summary: String
        if peers == 0 {
            summary = "Looking for peers"
        } else {
            let reach = reachLevel
            summary = "\(peers) connected, \(reach.label.lowercased()) reach"
        }
        summary += ", \(compactRate(bytesInPerMinute)) in and \(compactRate(bytesOutPerMinute)) out per minute"
        if isRelaying {
            summary += ", relaying"
        }
        return summary
    }
}
