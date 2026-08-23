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
            appState.colors.background
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
                    .font(AppType.ui(40, weight: .semibold))
                    .foregroundColor(appState.colors.onAccentFill)
                    .frame(width: 72, height: 72)
                    .background(appState.colors.accentFill)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text("Remove Ads")
                    .font(AppType.display(36))
                    .tracking(-1.4)
                    .foregroundColor(appState.colors.text)

                Text("Enjoy Closed Captioner without banner or interstitial ads. One-time purchase — yours forever.")
                    .font(AppType.ui(16, weight: .medium))
                    .foregroundColor(appState.colors.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if premiumManager.isPremium {
                    Text("Ads removed — thank you!")
                        .font(AppType.ui(17, weight: .bold))
                        .foregroundColor(appState.colors.accent)
                } else {
                    Button {
                        Task { await premiumManager.purchaseRemoveAds() }
                    } label: {
                        Group {
                            if premiumManager.purchaseInProgress {
                                ProgressView()
                                    .tint(appState.colors.onAccent)
                            } else {
                                Text("Remove Ads — \(premiumManager.removeAdsDisplayPrice)")
                                    .font(AppType.ui(17, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(appState.colors.accent)
                        .foregroundColor(appState.colors.onAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(premiumManager.purchaseInProgress)
                    .padding(.horizontal, 32)

                    Button("Restore Purchases") {
                        Task { await premiumManager.restorePurchases() }
                    }
                    .font(AppType.ui(15, weight: .semibold))
                    .foregroundColor(appState.colors.muted)
                    .disabled(premiumManager.purchaseInProgress)
                }

                if let errorMessage = premiumManager.errorMessage {
                    Text(errorMessage)
                        .font(AppType.ui(14, weight: .medium))
                        .foregroundColor(appState.colors.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()
            }
        }
    }
}
