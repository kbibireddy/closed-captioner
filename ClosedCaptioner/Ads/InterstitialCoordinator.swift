//
//  InterstitialCoordinator.swift
//  ClosedCaptioner
//

import UIKit

@MainActor
final class InterstitialCoordinator {
    static let shared = InterstitialCoordinator()

    private let manager = InterstitialAdManager()
    private var micStopCount = 0

    private init() {}

    func prepare() {
        guard !PremiumManager.shared.isPremium else { return }
        manager.load()
    }

    /// Show interstitial after closing history (best-effort if not yet loaded).
    func presentAfterHistoryClose() {
        guard !PremiumManager.shared.isPremium else { return }
        if AdsBootstrap.requestTrackingIfNeeded() {
            manager.load()
            return
        }
        presentIfPossible()
    }

    /// Count a mic stop; present interstitial every 3rd stop when allowed.
    func recordMicStop(allowPresent: Bool) {
        guard !PremiumManager.shared.isPremium else { return }
        AdsBootstrap.requestTrackingIfNeeded()
        micStopCount += 1
        guard allowPresent, micStopCount % 3 == 0 else { return }
        presentIfPossible()
    }

    private func presentIfPossible() {
        if AdsBootstrap.requestTrackingIfNeeded() {
            manager.load()
            return
        }
        guard let root = UIViewController.adsRootViewController else {
            manager.load()
            return
        }
        let presenter = root.adsTopMostPresented
        _ = manager.present(from: presenter)
    }
}

extension UIViewController {
    static var adsRootViewController: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap(\.windows)
        return windows.first(where: \.isKeyWindow)?.rootViewController
            ?? windows.first?.rootViewController
    }

    var adsTopMostPresented: UIViewController {
        var top = self
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
