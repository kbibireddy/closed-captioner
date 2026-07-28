//
//  InterstitialAdManager.swift
//  ClosedCaptioner
//

import GoogleMobileAds
import UIKit

@MainActor
final class InterstitialAdManager: NSObject {
    private var interstitialAd: InterstitialAd?
    private var isLoading = false

    func load() {
        guard !isLoading, interstitialAd == nil else { return }
        isLoading = true

        Task {
            do {
                let ad = try await InterstitialAd.load(
                    with: AdConfig.interstitialAdUnitID,
                    request: Request()
                )
                self.interstitialAd = ad
                ad.fullScreenContentDelegate = self
                self.isLoading = false
                print("[InterstitialAd] loaded")
            } catch {
                self.isLoading = false
                print("[InterstitialAd] load failed: \(error.localizedDescription)")
            }
        }
    }

    /// Presents a loaded interstitial if available, then preloads the next one.
    @discardableResult
    func present(from viewController: UIViewController) -> Bool {
        guard let ad = interstitialAd else {
            load()
            return false
        }

        interstitialAd = nil
        ad.present(from: viewController)
        return true
    }
}

extension InterstitialAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        load()
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        print("[InterstitialAd] present failed: \(error.localizedDescription)")
        load()
    }
}
