//
//  ControlsView.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

/// Top bar → top banner → captions (behind spacer) → bottom banner → bottom bar.
/// One VStack so banners cannot overlay the control buttons.
struct ControlsView: View {
    @ObservedObject var micController: MicController
    @ObservedObject var appState: AppStateViewModel
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
                    .font(AppType.ui(18, weight: .semibold))
                    .foregroundColor(appState.colors.text)
                    .appChromeButton(for: appState.colors)
            }
            .accessibilityLabel("Settings")

            Spacer()
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
                    .font(AppType.ui(18, weight: .semibold))
                    .foregroundColor(appState.colors.text)
                    .appChromeButton(for: appState.colors)
            }
            .accessibilityLabel("Keyboard")

            Spacer()

            Image(systemName: micController.isRecording ? "stop.fill" : "mic.fill")
                .font(AppType.ui(22, weight: .bold))
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
                    .font(AppType.ui(18, weight: .semibold))
                    .foregroundColor(appState.colors.text)
                    .appChromeButton(for: appState.colors)
            }
            .accessibilityLabel("Clear")
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }
}
