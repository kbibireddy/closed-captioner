//
//  BannerAdView.swift
//  ClosedCaptioner
//

import GoogleMobileAds
import SwiftUI
import UIKit

/// Anchored adaptive banner sized to the available width so the creative is fully visible.
struct BannerAdView: View {
    let adUnitID: String
    @State private var availableWidth: CGFloat = 0

    private var adSize: AdSize {
        let width = max(availableWidth, 1)
        return currentOrientationAnchoredAdaptiveBanner(width: width)
    }

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: availableWidth > 0 ? adSize.size.height : 50)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: BannerWidthKey.self, value: geo.size.width)
                }
            )
            .onPreferenceChange(BannerWidthKey.self) { newWidth in
                let width = floor(newWidth)
                if width > 0, abs(width - availableWidth) > 0.5 {
                    availableWidth = width
                }
            }
            .overlay {
                if availableWidth > 0 {
                    BannerViewRepresentable(adUnitID: adUnitID, adSize: adSize)
                        .frame(width: adSize.size.width, height: adSize.size.height)
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }
}

private struct BannerWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct BannerViewRepresentable: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear
        container.clipsToBounds = true
        container.isUserInteractionEnabled = true

        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIViewController.adsRootViewController
        banner.delegate = context.coordinator
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.clipsToBounds = true
        container.addSubview(banner)

        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            banner.topAnchor.constraint(equalTo: container.topAnchor),
            banner.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        context.coordinator.banner = banner
        banner.load(Request())
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        guard let banner = context.coordinator.banner else { return }
        banner.rootViewController = UIViewController.adsRootViewController
        if !isAdSizeEqualToSize(size1: banner.adSize, size2: adSize) {
            banner.adSize = adSize
            banner.load(Request())
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
        adSize.size
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        weak var banner: BannerView?

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            AppLog.debug("[BannerAd] did receive ad")
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            AppLog.debug("[BannerAd] failed: \(error.localizedDescription)")
        }
    }
}
