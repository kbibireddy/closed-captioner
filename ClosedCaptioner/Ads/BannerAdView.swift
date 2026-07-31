//
//  BannerAdView.swift
//  ClosedCaptioner
//

import GoogleMobileAds
import SwiftUI
import UIKit

/// Anchored adaptive banner using Google's recommended size for the given width.
struct BannerAdView: View {
    let adUnitID: String
    @State private var bannerHeight: CGFloat = 50

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 320)
            let adSize = currentOrientationAnchoredAdaptiveBanner(width: width)

            BannerViewRepresentable(adUnitID: adUnitID, adSize: adSize)
                .frame(width: adSize.size.width, height: adSize.size.height)
                .frame(maxWidth: .infinity)
                .onAppear {
                    bannerHeight = adSize.size.height
                }
                .onChange(of: geometry.size.width) { _ in
                    bannerHeight = adSize.size.height
                }
        }
        .frame(height: bannerHeight)
        .frame(maxWidth: .infinity)
    }
}

private struct BannerViewRepresentable: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIViewController.adsRootViewController
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        banner.rootViewController = UIViewController.adsRootViewController
        if !isAdSizeEqualToSize(size1: banner.adSize, size2: adSize) {
            banner.adSize = adSize
            banner.load(Request())
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("[BannerAd] did receive ad")
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("[BannerAd] failed: \(error.localizedDescription)")
        }
    }
}
