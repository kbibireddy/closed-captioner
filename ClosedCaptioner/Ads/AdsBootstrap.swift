//
//  AdsBootstrap.swift
//  ClosedCaptioner
//

import AppTrackingTransparency
import GoogleMobileAds

enum AdsBootstrap {
    private static var hasStarted = false

    @MainActor
    static func configureAdsIfNeeded(isPremium: Bool) {
        guard !isPremium else { return }
        startAdsIfNeeded()
    }

    @MainActor
    static func startAdsIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true

        MobileAds.shared.start { _ in
            Task { @MainActor in
                InterstitialCoordinator.shared.prepare()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
