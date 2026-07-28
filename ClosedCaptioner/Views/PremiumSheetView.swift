//
//  PremiumSheetView.swift
//  ClosedCaptioner
//

import SwiftUI

struct PremiumSheetView: View {
    @ObservedObject var appState: AppStateViewModel
    @ObservedObject private var premiumManager = PremiumManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            appState.colorMode.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    DoneButton(appState: appState, text: "Close") {
                        dismiss()
                    }
                }
                .padding()

                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .regular))
                    .foregroundColor(appState.colorMode.text)

                Text("Remove Ads")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(appState.colorMode.text)

                Text("Enjoy Closed Captioner without banner or interstitial ads. One-time purchase — yours forever.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(appState.colorMode.text.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if premiumManager.isPremium {
                    Text("Ads removed — thank you!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                } else {
                    Button {
                        Task { await premiumManager.purchaseRemoveAds() }
                    } label: {
                        Group {
                            if premiumManager.purchaseInProgress {
                                ProgressView()
                                    .tint(appState.colorMode.background)
                            } else {
                                Text("Remove Ads — \(premiumManager.removeAdsDisplayPrice)")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(appState.colorMode.text)
                        .foregroundColor(appState.colorMode.background)
                        .cornerRadius(10)
                    }
                    .disabled(premiumManager.purchaseInProgress)
                    .padding(.horizontal, 32)

                    Button("Restore Purchases") {
                        Task { await premiumManager.restorePurchases() }
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(appState.colorMode.text.opacity(0.8))
                    .disabled(premiumManager.purchaseInProgress)
                }

                if let errorMessage = premiumManager.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()
            }
        }
    }
}
