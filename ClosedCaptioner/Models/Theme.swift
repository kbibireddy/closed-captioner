//
//  Theme.swift
//  ClosedCaptioner
//
//  Visual language: editorial serif headlines, rounded UI, and selectable
//  palettes. Day / Night control light vs dark; AppTheme tints them.
//  Stealth is a low-contrast theme, not a third lighting mode.
//

import SwiftUI

enum AppType {
    /// Fraunces-style display type via New York.
    static func display(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Source Sans-style UI type via SF Rounded.
    static func ui(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

enum AppRadius {
    static let card: CGFloat = 18
    static let control: CGFloat = 14
}

/// Resolved colors for the current theme + day/night mode.
struct ThemeColors {
    let background: Color
    let text: Color
    let muted: Color
    let card: Color
    let line: Color
    let buttonBackground: Color
    let accent: Color
    let onAccent: Color
    /// Bright chip behind the mic and product icons.
    let accentFill: Color
    /// High-contrast ink drawn on `accentFill` (never the same as the fill).
    let onAccentFill: Color
    let danger: Color
    let cardShadow: Color
}

/// User-selectable palettes. Grove is the OfferLab default already in the app.
enum AppTheme: String, CaseIterable, Identifiable {
    case grove
    case harbor
    case ember
    case ink
    case dusk
    case stealth

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grove: return "Grove"
        case .harbor: return "Harbor"
        case .ember: return "Ember"
        case .ink: return "Ink"
        case .dusk: return "Dusk"
        case .stealth: return "Stealth"
        }
    }

    var subtitle: String {
        switch self {
        case .grove: return "Forest and lime"
        case .harbor: return "Navy and sky"
        case .ember: return "Terracotta and cream"
        case .ink: return "Cobalt and paper"
        case .dusk: return "Plum and blush"
        case .stealth: return "Low contrast, private"
        }
    }

    var previewSwatches: [Color] {
        let day = colors(for: .day)
        let night = colors(for: .night)
        return [day.background, day.accent, day.accentFill, night.background]
    }

    func colors(for mode: ColorMode) -> ThemeColors {
        let seed = Self.seeds[self]!
        switch mode {
        case .day:
            return ThemeColors(
                background: seed.paper,
                text: seed.ink,
                muted: seed.muted,
                card: seed.card,
                line: seed.line,
                buttonBackground: seed.track,
                accent: seed.accent,
                onAccent: seed.onAccent,
                accentFill: seed.accentFill,
                onAccentFill: seed.onAccentFill,
                danger: seed.danger,
                cardShadow: self == .stealth
                    ? .clear
                    : Color(hex: 0x1F2D25, opacity: 0.08)
            )
        case .night:
            return ThemeColors(
                background: seed.nightBg,
                text: seed.nightText,
                muted: seed.nightMuted,
                card: seed.nightCard,
                line: seed.nightLine,
                buttonBackground: seed.nightCard,
                accent: seed.nightAccent,
                onAccent: seed.nightOnAccent,
                accentFill: seed.nightAccentFill,
                onAccentFill: seed.nightOnAccentFill,
                danger: seed.danger,
                cardShadow: self == .stealth ? .clear : Color.black.opacity(0.28)
            )
        }
    }

    private struct Seed {
        let paper, ink, muted, card, line, track: Color
        let accent, onAccent, accentFill, onAccentFill, danger: Color
        let nightBg, nightText, nightMuted, nightCard, nightLine: Color
        let nightAccent, nightOnAccent, nightAccentFill, nightOnAccentFill: Color
    }

    private static let seeds: [AppTheme: Seed] = [
        .grove: Seed(
            paper: Color(hex: 0xF4F1E9),
            ink: Color(hex: 0x17211B),
            muted: Color(hex: 0x66736B),
            card: Color(hex: 0xFFFDF8),
            line: Color(hex: 0xD9D8CF),
            track: Color(hex: 0xE8E9E1),
            accent: Color(hex: 0x174F3D),
            onAccent: Color(hex: 0xF4F1E9),
            accentFill: Color(hex: 0xD8F36B),
            onAccentFill: Color(hex: 0x174F3D),
            danger: Color(hex: 0xED765E),
            nightBg: Color(hex: 0x10231C),
            nightText: Color(hex: 0xF4F1E9),
            nightMuted: Color(hex: 0x8B9A91),
            nightCard: Color(hex: 0x17352B),
            nightLine: Color(hex: 0x2C4F42),
            nightAccent: Color(hex: 0xD8F36B),
            nightOnAccent: Color(hex: 0x174F3D),
            nightAccentFill: Color(hex: 0xD8F36B),
            nightOnAccentFill: Color(hex: 0x174F3D)
        ),
        .harbor: Seed(
            paper: Color(hex: 0xF3EEE4),
            ink: Color(hex: 0x1A2A38),
            muted: Color(hex: 0x6A7A86),
            card: Color(hex: 0xFFFAF3),
            line: Color(hex: 0xD8D2C6),
            track: Color(hex: 0xE6E0D4),
            accent: Color(hex: 0x1D4E6B),
            onAccent: Color(hex: 0xF3EEE4),
            accentFill: Color(hex: 0x9FD4E8),
            onAccentFill: Color(hex: 0x1D4E6B),
            danger: Color(hex: 0xD46A5C),
            nightBg: Color(hex: 0x0D1C28),
            nightText: Color(hex: 0xEEF4F7),
            nightMuted: Color(hex: 0x8AA0AE),
            nightCard: Color(hex: 0x163044),
            nightLine: Color(hex: 0x2A4D63),
            nightAccent: Color(hex: 0x7EC8E3),
            nightOnAccent: Color(hex: 0x0D1C28),
            nightAccentFill: Color(hex: 0x7EC8E3),
            nightOnAccentFill: Color(hex: 0x0D1C28)
        ),
        .ember: Seed(
            paper: Color(hex: 0xF6EEE6),
            ink: Color(hex: 0x2B1B14),
            muted: Color(hex: 0x8A6F62),
            card: Color(hex: 0xFFF8F2),
            line: Color(hex: 0xE0D0C4),
            track: Color(hex: 0xEADFD6),
            accent: Color(hex: 0xB54A2A),
            onAccent: Color(hex: 0xFFF8F2),
            accentFill: Color(hex: 0xF0B48A),
            onAccentFill: Color(hex: 0x2B1B14),
            danger: Color(hex: 0xB54A2A),
            nightBg: Color(hex: 0x1A1210),
            nightText: Color(hex: 0xF6EEE6),
            nightMuted: Color(hex: 0xB09A8C),
            nightCard: Color(hex: 0x2A1C18),
            nightLine: Color(hex: 0x4A3228),
            nightAccent: Color(hex: 0xE08A5D),
            nightOnAccent: Color(hex: 0x1A1210),
            nightAccentFill: Color(hex: 0xE08A5D),
            nightOnAccentFill: Color(hex: 0x1A1210)
        ),
        .ink: Seed(
            paper: Color(hex: 0xF2F0EA),
            ink: Color(hex: 0x141418),
            muted: Color(hex: 0x6E6D68),
            card: Color(hex: 0xFBFAF6),
            line: Color(hex: 0xD8D6CE),
            track: Color(hex: 0xE6E4DC),
            accent: Color(hex: 0x2C4A9A),
            onAccent: Color(hex: 0xFBFAF6),
            accentFill: Color(hex: 0xC5D0F0),
            onAccentFill: Color(hex: 0x1A2A5C),
            danger: Color(hex: 0xC45C4A),
            nightBg: Color(hex: 0x101014),
            nightText: Color(hex: 0xF2F0EA),
            nightMuted: Color(hex: 0x9A9890),
            nightCard: Color(hex: 0x1C1C22),
            nightLine: Color(hex: 0x34343C),
            nightAccent: Color(hex: 0x8AA4E8),
            nightOnAccent: Color(hex: 0x101014),
            nightAccentFill: Color(hex: 0x8AA4E8),
            nightOnAccentFill: Color(hex: 0x101014)
        ),
        .dusk: Seed(
            paper: Color(hex: 0xF5EEF2),
            ink: Color(hex: 0x2A1A2C),
            muted: Color(hex: 0x7A6578),
            card: Color(hex: 0xFDF7FA),
            line: Color(hex: 0xE0D0DA),
            track: Color(hex: 0xEADCE4),
            accent: Color(hex: 0x6B2D6E),
            onAccent: Color(hex: 0xFDF7FA),
            accentFill: Color(hex: 0xE8B8E0),
            onAccentFill: Color(hex: 0x3A1840),
            danger: Color(hex: 0xC45C6A),
            nightBg: Color(hex: 0x161018),
            nightText: Color(hex: 0xF5EEF2),
            nightMuted: Color(hex: 0xB098A8),
            nightCard: Color(hex: 0x261C28),
            nightLine: Color(hex: 0x443848),
            nightAccent: Color(hex: 0xE0A8D8),
            nightOnAccent: Color(hex: 0x161018),
            nightAccentFill: Color(hex: 0xE0A8D8),
            nightOnAccentFill: Color(hex: 0x2A1A2C)
        ),
        .stealth: Seed(
            paper: Color(hex: 0x1C201E),
            ink: Color(hex: 0x3A4240),
            muted: Color(hex: 0x323834),
            card: Color(hex: 0x222826),
            line: Color(hex: 0x2A302E),
            track: Color(hex: 0x222826),
            accent: Color(hex: 0x3A4240),
            onAccent: Color(hex: 0x1C201E),
            accentFill: Color(hex: 0x2A302E),
            onAccentFill: Color(hex: 0x4A524E),
            danger: Color(hex: 0x4A3A38),
            nightBg: Color(hex: 0x141816),
            nightText: Color(hex: 0x2C322F),
            nightMuted: Color(hex: 0x262C2A),
            nightCard: Color(hex: 0x1A1E1C),
            nightLine: Color(hex: 0x242A27),
            nightAccent: Color(hex: 0x2C322F),
            nightOnAccent: Color(hex: 0x141816),
            nightAccentFill: Color(hex: 0x1A1E1C),
            nightOnAccentFill: Color(hex: 0x2C322F)
        )
    ]
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

extension View {
    func appCard(for colors: ThemeColors) -> some View {
        self
            .padding(16)
            .background(colors.card)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(colors.line, lineWidth: 1)
            )
            .shadow(color: colors.cardShadow, radius: 18, x: 0, y: 8)
    }

    func appChromeButton(for colors: ThemeColors) -> some View {
        self
            .frame(width: 44, height: 44)
            .background(colors.buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    .stroke(colors.line, lineWidth: 1)
            )
    }
}
