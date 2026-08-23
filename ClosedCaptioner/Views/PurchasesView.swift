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
                .padding(20)
            }

            Button {
                Task { await premiumManager.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(AppType.ui(15, weight: .semibold))
                    .foregroundColor(appState.colors.muted)
            }
            .disabled(premiumManager.purchaseInProgress)
            .padding(.bottom, 12)

            if let errorMessage = premiumManager.errorMessage {
                Text(errorMessage)
                    .font(AppType.ui(13, weight: .medium))
                    .foregroundColor(appState.colors.danger)
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
                    .font(AppType.ui(22, weight: .semibold))
                    .foregroundColor(appState.colors.onAccentFill)
                    .frame(width: 44, height: 44)
                    .background(appState.colors.accentFill)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(definition.title)
                        .font(AppType.ui(18, weight: .bold))
                        .foregroundColor(appState.colors.text)

                    Text(definition.subtitle)
                        .font(AppType.ui(14, weight: .medium))
                        .foregroundColor(appState.colors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if isOwned {
                Text("Owned")
                    .font(AppType.ui(15, weight: .bold))
                    .foregroundColor(appState.colors.accent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Button {
                    Task {
                        if premiumManager.product(for: definition) == nil {
                            await premiumManager.loadProducts()
                        } else {
                            await premiumManager.purchase(definition)
                        }
                    }
                } label: {
                    Group {
                        if isPurchasingThis || !premiumManager.productsLoaded {
                            ProgressView()
                                .tint(appState.colors.onAccent)
                        } else if premiumManager.product(for: definition) == nil {
                            Text("Retry")
                                .font(AppType.ui(16, weight: .bold))
                        } else {
                            Text(premiumManager.displayPrice(for: definition))
                                .font(AppType.ui(16, weight: .bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(appState.colors.accent)
                    .foregroundColor(appState.colors.onAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(premiumManager.purchaseInProgress || !premiumManager.productsLoaded)
            }
        }
        .appCard(for: appState.colors)
    }
}
