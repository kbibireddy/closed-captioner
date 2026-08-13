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
                .padding(.vertical, 8)
                .background(appState.colorMode.background)
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
                .padding(.vertical, 4)
                .background(appState.colorMode.background)
                .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(2)
    }

    private var topBar: some View {
        HStack {
            Button(action: {
                appState.toggleSettings()
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(appState.colorMode.text)
            }
            .padding(.leading)
            .accessibilityLabel("Settings")

            Spacer()

            Picker("Color Mode", selection: $appState.colorMode) {
                ForEach(ColorMode.allCases, id: \.self) { mode in
                    Image(systemName: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
            .tint(appState.colorMode.text.opacity(0.3))
            .colorMultiply(appState.colorMode.text)
            .padding(.trailing)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
    }

    private var bottomBar: some View {
        HStack {
            Button(action: {
                appState.toggleKeyboard()
            }) {
                Image(systemName: "keyboard")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(appState.colorMode.text)
            }
            .padding(.leading)

            Spacer()

            Image(systemName: micController.isRecording ? "stop.fill" : "mic")
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(micController.isRecording ? .red : appState.colorMode.text)
                .padding()
                .contentShape(Circle())
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { _ in
                }, perform: {
                    if micController.isRecording {
                        micController.stopRecording()
                    } else {
                        micController.startRecording()
                    }
                })

            Spacer()

            Button(action: onClear) {
                Image(systemName: "eraser.fill")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(appState.colorMode.text)
            }
            .padding(.trailing)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
    }
}
