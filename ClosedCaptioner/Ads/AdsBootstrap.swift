//
//  AdsBootstrap.swift
//  ClosedCaptioner
//

import AppTrackingTransparency
import GoogleMobileAds
import UIKit

/// Starts AdMob only after ATT has been prompted (or already decided).
/// Reviewers must see the system tracking dialog on a fresh install before ads load.
enum AdsBootstrap {
    private static var hasStarted = false
    private static var hasRequestedTracking = false
    private static var hasScheduledForegroundPrep = false

    /// Call when the UI is on-screen and active. Prompts ATT first, then starts AdMob.
    /// `onReady` runs after ATT is handled (or skipped for premium) so other permission alerts do not cover ATT.
    @MainActor
    static func prepareForForeground(isPremium: Bool, onReady: (() -> Void)? = nil) {
        guard !hasScheduledForegroundPrep else { return }
        hasScheduledForegroundPrep = true

        Task { @MainActor in
            // ATT requires an active key window; brief delay after becoming active.
            try? await Task.sleep(nanoseconds: 800_000_000)

            if PremiumManager.shared.isPremium || isPremium {
                onReady?()
                return
            }

            await requestTrackingAuthorizationIfNeeded()
            startAdsIfNeeded()
            PremiumManager.shared.markAdsStarted()
            onReady?()
        }
    }

    /// Legacy entry from PremiumManager: do not start ads here (wait for foreground + ATT).
    @MainActor
    static func configureAdsIfNeeded(isPremium: Bool) {
        guard !isPremium else { return }
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

    /// Returns `true` when the system dialog was shown (callers should avoid stacking UI).
    @MainActor
    @discardableResult
    static func requestTrackingIfNeeded() -> Bool {
        guard !hasRequestedTracking else { return false }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            hasRequestedTracking = true
            return false
        }
        hasRequestedTracking = true
        ATTrackingManager.requestTrackingAuthorization { _ in }
        return true
    }

    @MainActor
    private static func requestTrackingAuthorizationIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            hasRequestedTracking = true
            return
        }
        guard !hasRequestedTracking else { return }
        hasRequestedTracking = true

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ATTrackingManager.requestTrackingAuthorization { _ in
                continuation.resume()
            }
        }
    }
}
