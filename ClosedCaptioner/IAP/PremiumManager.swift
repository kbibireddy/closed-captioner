//
//  PremiumManager.swift
//  ClosedCaptioner
//

import Foundation
import StoreKit

@MainActor
final class PremiumManager: ObservableObject {
    static let shared = PremiumManager()

    /// Product ID → StoreKit product
    @Published private(set) var productsByID: [String: Product] = [:]
    /// Owned non-consumable product IDs
    @Published private(set) var ownedProductIDs: Set<String> = []
    @Published private(set) var purchaseInProgress = false
    @Published private(set) var purchasingProductID: String?
    @Published var errorMessage: String?

    private var transactionListener: Task<Void, Never>?

    /// Convenience: ads removed entitlement
    var isPremium: Bool {
        ownedProductIDs.contains(IAPConfig.removeAdsProductID)
    }

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
            AdsBootstrap.configureAdsIfNeeded(isPremium: isPremium)
        }
    }

    func product(for definition: IAPProductDefinition) -> Product? {
        productsByID[definition.productID]
    }

    func displayPrice(for definition: IAPProductDefinition) -> String {
        productsByID[definition.productID]?.displayPrice ?? definition.fallbackPrice
    }

    func isOwned(_ productID: String) -> Bool {
        ownedProductIDs.contains(productID)
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: IAPConfig.allProductIDs)
            var map: [String: Product] = [:]
            for product in products {
                map[product.id] = product
            }
            productsByID = map
        } catch {
            print("[PremiumManager] Failed to load products: \(error.localizedDescription)")
        }
    }

    func refreshEntitlements() async {
        var owned: Set<String> = []
        let knownIDs = Set(IAPConfig.allProductIDs)

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard knownIDs.contains(transaction.productID) else { continue }
            owned.insert(transaction.productID)
        }

        let wasPremium = isPremium
        ownedProductIDs = owned

        if wasPremium != isPremium {
            AdsBootstrap.configureAdsIfNeeded(isPremium: isPremium)
        }
    }

    func purchase(_ definition: IAPProductDefinition) async {
        await purchase(productID: definition.productID)
    }

    func purchase(productID: String) async {
        guard let product = productsByID[productID] else {
            errorMessage = "Purchase unavailable. Try again later."
            await loadProducts()
            return
        }

        purchaseInProgress = true
        purchasingProductID = productID
        errorMessage = nil
        defer {
            purchaseInProgress = false
            purchasingProductID = nil
        }

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

    /// Backward-compatible helper for Remove Ads.
    func purchaseRemoveAds() async {
        await purchase(productID: IAPConfig.removeAdsProductID)
    }

    var removeAdsDisplayPrice: String {
        if let definition = IAPConfig.catalog.first(where: { $0.productID == IAPConfig.removeAdsProductID }) {
            return displayPrice(for: definition)
        }
        return "$0.99"
    }

    func restorePurchases() async {
        purchaseInProgress = true
        errorMessage = nil
        defer { purchaseInProgress = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if ownedProductIDs.isEmpty {
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
