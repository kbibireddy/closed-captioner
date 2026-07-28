//
//  PremiumManager.swift
//  ClosedCaptioner
//

import Foundation
import StoreKit

@MainActor
final class PremiumManager: ObservableObject {
    static let shared = PremiumManager()

    @Published private(set) var isPremium = false
    @Published private(set) var removeAdsProduct: Product?
    @Published private(set) var purchaseInProgress = false
    @Published var errorMessage: String?

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
            AdsBootstrap.configureAdsIfNeeded(isPremium: isPremium)
        }
    }

    var removeAdsDisplayPrice: String {
        removeAdsProduct?.displayPrice ?? "$4.99"
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [IAPConfig.removeAdsProductID])
            removeAdsProduct = products.first
        } catch {
            print("[PremiumManager] Failed to load products: \(error.localizedDescription)")
        }
    }

    func refreshEntitlements() async {
        var entitled = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == IAPConfig.removeAdsProductID else { continue }
            entitled = true
            break
        }

        let wasPremium = isPremium
        isPremium = entitled

        if wasPremium != isPremium {
            AdsBootstrap.configureAdsIfNeeded(isPremium: isPremium)
        }
    }

    func purchaseRemoveAds() async {
        guard let product = removeAdsProduct else {
            errorMessage = "Purchase unavailable. Try again later."
            await loadProducts()
            return
        }

        purchaseInProgress = true
        errorMessage = nil
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = "Purchase could not be verified."
                    return
                }
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        purchaseInProgress = true
        errorMessage = nil
        defer { purchaseInProgress = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isPremium {
                errorMessage = "No previous purchase found for this Apple ID."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await PremiumManager.shared.refreshEntitlements()
            }
        }
    }
}
