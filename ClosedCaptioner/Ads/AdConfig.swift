//
//  AdConfig.swift
//  ClosedCaptioner
//
//  AdMob IDs. Defaults are Google's official test IDs.
//  Replace PRODUCTION placeholders with your AdMob units before release.
//

import Foundation

enum AdConfig {
    /// Info.plist `GADApplicationIdentifier` must match this app ID.
    static let applicationID = "ca-app-pub-7546535789763376~8583143111"

    /// Adaptive banner - top (below top icons)
    static let topBannerAdUnitID = "ca-app-pub-7546535789763376/4811419062"

    /// Adaptive banner - bottom (above bottom icons)
    static let bottomBannerAdUnitID = "ca-app-pub-7546535789763376/3534684777"

    /// Interstitial - on history close and every 3rd mic stop
    static let interstitialAdUnitID = "ca-app-pub-7546535789763376/2572836751"
}
