//
//  PurchasesView.swift
//  ClosedCaptioner
//

import SwiftUI

struct PurchasesView: View {
    @ObservedObject var appState: AppStateViewModel
    @ObservedObject private var premiumManager = PremiumManager.shared

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(IAPConfig.catalog) { item in
                        PurchaseProductRow(
                            definition: item,
                            appState: appState,
                            premiumManager: premiumManager
                        )
                    }
                }
                .padding()
            }

            Button {
                Task { await premiumManager.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(appState.colorMode.text.opacity(0.8))
            }
            .disabled(premiumManager.purchaseInProgress)
            .padding(.bottom, 12)

            if let errorMessage = premiumManager.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .task {
            await premiumManager.loadProducts()
        }
    }
}

struct PurchaseProductRow: View {
    let definition: IAPProductDefinition
    @ObservedObject var appState: AppStateViewModel
    @ObservedObject var premiumManager: PremiumManager

    private var isOwned: Bool {
        premiumManager.isOwned(definition.productID)
    }

    private var isPurchasingThis: Bool {
        premiumManager.purchaseInProgress
            && premiumManager.purchasingProductID == definition.productID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: definition.systemImage)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(appState.colorMode.text)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(definition.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(appState.colorMode.text)

                    Text(definition.subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(appState.colorMode.text.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if isOwned {
                Text("Owned")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Button {
                    Task { await premiumManager.purchase(definition) }
                } label: {
                    Group {
                        if isPurchasingThis {
                            ProgressView()
                                .tint(appState.colorMode.background)
                        } else {
                            Text(premiumManager.displayPrice(for: definition))
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(appState.colorMode.text)
                    .foregroundColor(appState.colorMode.background)
                    .cornerRadius(10)
                }
                .disabled(premiumManager.purchaseInProgress)
            }
        }
        .padding(16)
        .background(appState.colorMode.buttonBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(appState.colorMode.text.opacity(0.15), lineWidth: 1)
        )
    }
}
