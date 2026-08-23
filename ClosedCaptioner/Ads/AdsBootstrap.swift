//
//  AdsBootstrap.swift
//  ClosedCaptioner
//

import AppTrackingTransparency
import GoogleMobileAds

enum AdsBootstrap {
    private static var hasStarted = false
    private static var hasRequestedTracking = false

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
    }

    /// Prompts ATT once, after a user action tied to ads (mic stop / interstitial).
    /// Returns `true` when the system dialog was shown so callers can skip stacking an interstitial on top of it.
    @MainActor
    @discardableResult
    static func requestTrackingIfNeeded() -> Bool {
        guard !hasRequestedTracking else { return false }
        hasRequestedTracking = true
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            return false
        }
        ATTrackingManager.requestTrackingAuthorization { _ in }
        return true
    }
}
