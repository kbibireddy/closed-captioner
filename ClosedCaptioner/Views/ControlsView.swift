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

            if p2pInbox.isListening {
                P2PRadioStatsView(
                    colors: appState.colors,
                    peers: p2pInbox.connectedPeerCount,
                    isRelaying: appState.relayMessages
                )
            }

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
                    ? "Stop listening for nearby messages"
                    : "Listen for nearby messages"
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

/// Compact nearby status to the left of the radio. Hidden when radio is off.
/// Detailed counters live under Settings → KPIs.
private struct P2PRadioStatsView: View {
    let colors: ThemeColors
    let peers: Int
    let isRelaying: Bool

    private var peopleLine: String {
        switch peers {
        case 0: return "Looking…"
        case 1: return "1 person"
        default: return "\(peers) people"
        }
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text("Nearby")
                .font(AppType.display(10, weight: .bold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundColor(colors.muted)
            Text(peopleLine)
                .font(AppType.display(13, weight: .semibold))
                .foregroundColor(colors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if isRelaying {
                Text("Relaying")
                    .font(AppType.display(10, weight: .medium))
                    .foregroundColor(colors.muted)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Nearby")
        .accessibilityValue(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        var summary = peopleLine
        if isRelaying {
            summary += ", relaying messages"
        }
        return summary
    }
}
