//
//  ControlsView.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

struct ControlsView: View {
    @ObservedObject var micController: MicController
    @ObservedObject var appState: AppStateViewModel
    @ObservedObject private var premiumManager = PremiumManager.shared
    let onClear: () -> Void

    private var showBanners: Bool {
        !premiumManager.isPremium
            && !appState.showHistory
            && !appState.showKeyboard
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top icons
            HStack {
                Button(action: {
                    appState.toggleHistory()
                }) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(appState.colorMode.text)
                }
                .padding()

                Spacer()

                if !premiumManager.isPremium {
                    Button(action: {
                        appState.togglePremium()
                    }) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(appState.colorMode.text.opacity(0.85))
                    }
                    .padding(.trailing, 4)
                    .accessibilityLabel("Remove Ads")
                }

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
            }
            .padding(.horizontal)

            if showBanners {
                BannerAdView(adUnitID: AdConfig.topBannerAdUnitID)
                    .padding(.top, 4)
            }

            Spacer(minLength: 0)

            if showBanners {
                BannerAdView(adUnitID: AdConfig.bottomBannerAdUnitID)
                    .padding(.bottom, 4)
            }

            // Bottom icons
            HStack {
                Button(action: {
                    appState.toggleKeyboard()
                }) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(appState.colorMode.text)
                }
                .padding()

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
                .padding()
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(2)
    }
}
