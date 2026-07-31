//
//  ControlsView.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

/// Layout (back → front): caption canvas (ContentView) → ad slots → button chrome.
/// Ads use Google adaptive sizes and sit in dedicated rows so they never cover controls.
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
        ZStack {
            // Ad presentation layer — between caption canvas (behind) and buttons (in front)
            adPresentationLayer
                .zIndex(1)

            // Button chrome — always above ads
            buttonChromeLayer
                .zIndex(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(2)
    }

    /// Reserves top/bottom chrome height, then places Google adaptive banners
    /// immediately inside that chrome so ads never overlap buttons.
    private var adPresentationLayer: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: Self.topChromeHeight)

            if showBanners {
                BannerAdView(adUnitID: AdConfig.topBannerAdUnitID)
                    .padding(.top, 30)
            }

            Spacer(minLength: 0)

            if showBanners {
                BannerAdView(adUnitID: AdConfig.bottomBannerAdUnitID)
                    .padding(.bottom, 30)
            }

            Color.clear
                .frame(height: Self.bottomChromeHeight)
        }
        .allowsHitTesting(showBanners)
    }

    private var buttonChromeLayer: some View {
        VStack(spacing: 0) {
            topBar
                .frame(height: Self.topChromeHeight)

            Spacer(minLength: 0)

            bottomBar
                .frame(height: Self.bottomChromeHeight)
        }
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
        .background(appState.colorMode.background.opacity(0.001))
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
        .background(appState.colorMode.background.opacity(0.001))
    }

    /// Matches top control row height so ad slot starts below icons.
    private static let topChromeHeight: CGFloat = 56
    /// Matches bottom control row height so ad slot ends above mic/keyboard/erase.
    private static let bottomChromeHeight: CGFloat = 64
}
