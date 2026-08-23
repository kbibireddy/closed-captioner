//
//  P2PMessageLogView.swift
//  ClosedCaptioner
//
//  Transparent live log above the bottom banner. Newest at the bottom.
//  Height hugs content, then grows and scrolls. Fade stays solid through
//  the lower half, then eases to clear at the top.
//

import SwiftUI

struct P2PMessageLogView: View {
    /// Original strip height. Max is that × 1.75, then +50% more.
    static let baseHeight: CGFloat = 50
    static var maxHeight: CGFloat { baseHeight * 1.75 * 1.5 }
    static let maxVisibleCharacters = 180

    let colors: ThemeColors
    let entries: [P2PLogEntry]

    @State private var contentHeight: CGFloat = 0

    private var isOverflowing: Bool {
        contentHeight > Self.maxHeight + 0.5
    }

    private var fittedHeight: CGFloat {
        let measured = contentHeight > 0 ? contentHeight : Self.oneLineHeight
        return min(measured, Self.maxHeight)
    }

    private static let oneLineHeight: CGFloat = 22

    var body: some View {
        logBody
            .onPreferenceChange(P2PLogContentHeightKey.self) { newHeight in
                if abs(newHeight - contentHeight) > 0.5 {
                    contentHeight = newHeight
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: fittedHeight, alignment: .bottom)
            .mask {
                if isOverflowing || entries.count >= 2 {
                    fadeMask
                } else {
                    Color.black
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Nearby message log")
    }

    @ViewBuilder
    private var logBody: some View {
        if isOverflowing {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    logStack
                }
                .onAppear {
                    scrollToEnd(proxy)
                }
                .onChange(of: entries.last?.id) { _ in
                    scrollToEnd(proxy)
                }
            }
        } else {
            logStack
        }
    }

    private var logStack: some View {
        VStack(alignment: .leading, spacing: 6) {
            if entries.isEmpty {
                Text("Listening for nearby messages…")
                    .font(AppType.display(13, weight: .medium))
                    .tracking(-0.3)
                    .foregroundColor(colors.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(entries) { entry in
                    logRow(entry)
                }
            }

            Color.clear
                .frame(height: 1)
                .id("p2p-log-end")
        }
        .padding(.horizontal, 16)
        .padding(.top, isOverflowing ? 10 : 2)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: P2PLogContentHeightKey.self, value: geo.size.height)
            }
        )
    }

    private func logRow(_ entry: P2PLogEntry) -> some View {
        let body = Self.displayText(entry.text)
        return (
            Text("[\(entry.senderName)] ")
                .font(AppType.display(13, weight: .medium))
                .tracking(-0.3)
                .foregroundColor(colors.accent)
            +
            Text(body)
                .font(AppType.display(13, weight: .medium))
                .tracking(-0.3)
                .foregroundColor(colors.text)
        )
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("\(entry.senderName), \(body)")
    }

    /// Solid from the bottom through 50% of height, gentle fade to 70%,
    /// then ease-in (power 2.4) to 0 at the top.
    private var fadeMask: some View {
        LinearGradient(
            stops: Self.fadeStops,
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private static var fadeStops: [Gradient.Stop] {
        let samples: [CGFloat] = [0, 0.50, 0.58, 0.70, 0.78, 0.86, 0.93, 1]
        return samples.map { y in
            Gradient.Stop(color: Color.black.opacity(fadeOpacity(fromBottom: y)), location: y)
        }
    }

    /// `y` is 0 at the bottom of the log, 1 at the top.
    private static func fadeOpacity(fromBottom y: CGFloat) -> CGFloat {
        if y <= 0.5 { return 1 }
        if y <= 0.7 {
            let t = (y - 0.5) / 0.2
            return 1 - 0.28 * pow(t, 1.2)
        }
        let t = min(max((y - 0.7) / 0.3, 0), 1)
        let opacityAt70: CGFloat = 0.72
        return opacityAt70 * pow(1 - t, 2.4)
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            proxy.scrollTo("p2p-log-end", anchor: .bottom)
        }
    }

    static func displayText(_ text: String) -> String {
        if text.count <= maxVisibleCharacters {
            return text
        }
        return String(text.prefix(maxVisibleCharacters)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }
}

private struct P2PLogContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
