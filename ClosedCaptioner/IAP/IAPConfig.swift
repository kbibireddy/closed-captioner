//
//  IAPConfig.swift
//  ClosedCaptioner
//

import Foundation

/// Catalog entry for an in-app purchase. Add new items here as products ship.
struct IAPProductDefinition: Identifiable, Hashable {
    let id: String
    let productID: String
    let title: String
    let subtitle: String
    let systemImage: String
    /// Fallback when StoreKit has not returned a localized price yet.
    let fallbackPrice: String
}

enum IAPConfig {
    /// Non-consumable — create in App Store Connect at $0.99.
    static let removeAdsProductID = "RaveSociety.ClosedCaptioner.removeAds"

    /// Ordered storefront list. Append future products without changing Purchases UI.
    static let catalog: [IAPProductDefinition] = [
        IAPProductDefinition(
            id: "removeAds",
            productID: removeAdsProductID,
            title: "Remove Ads",
            subtitle: "Remove all banner and interstitial ads permanently. One-time purchase.",
            systemImage: "rectangle.badge.xmark",
            fallbackPrice: "$0.99"
        )
    ]

    static var allProductIDs: [String] {
        catalog.map(\.productID)
    }
}
