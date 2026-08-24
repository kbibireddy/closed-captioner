//
//  AppStateViewModel.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

/// View model that manages application state including UI modes and animations
class AppStateViewModel: ObservableObject {
    private static let themeDefaultsKey = "ClosedCaptioner.appTheme"
    private static let colorModeDefaultsKey = "ClosedCaptioner.colorMode"
    private static let fontChoiceDefaultsKey = "ClosedCaptioner.appFont"
    private static let displayNameDefaultsKey = "ClosedCaptioner.displayName"
    private static let relayMessagesDefaultsKey = "ClosedCaptioner.relayMessages"
    private static let radioKeepAliveDefaultsKey = "ClosedCaptioner.radioKeepAlive"
    private static let emojiDetectionDefaultsKey = "ClosedCaptioner.emojiDetection"

    /// Day or night appearance
    @Published var colorMode: ColorMode {
        didSet {
            UserDefaults.standard.set(colorMode.rawValue, forKey: Self.colorModeDefaultsKey)
        }
    }
    /// User-selected palette. Grove is the default OfferLab look.
    @Published var theme: AppTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: Self.themeDefaultsKey)
        }
    }
    /// App-wide typeface. SF Pro (system) is the default.
    @Published var fontChoice: AppFontChoice {
        didSet {
            UserDefaults.standard.set(fontChoice.rawValue, forKey: Self.fontChoiceDefaultsKey)
            AppType.fontChoice = fontChoice
        }
    }
    /// Nearby identity. Defaults to the device host name; user can set any name.
    @Published var displayName: String {
        didSet {
            UserDefaults.standard.set(displayName, forKey: Self.displayNameDefaultsKey)
        }
    }
    /// When radio is on, forward nearby captions to other neighbors. Default on.
    @Published var relayMessages: Bool {
        didSet {
            UserDefaults.standard.set(relayMessages, forKey: Self.relayMessagesDefaultsKey)
        }
    }
    /// Auto-off for radio (and relay) after this duration. Default 30 minutes.
    @Published var radioKeepAlive: RadioKeepAlive {
        didSet {
            UserDefaults.standard.set(radioKeepAlive.rawValue, forKey: Self.radioKeepAliveDefaultsKey)
        }
    }
    /// Append suggested emojis after speech text stabilizes. Default off (experimental).
    @Published var emojiDetectionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(emojiDetectionEnabled, forKey: Self.emojiDetectionDefaultsKey)
        }
    }
    /// Whether the keyboard editing view is visible
    @Published var showKeyboard = false
    /// Whether Settings (History / Purchases) is visible
    @Published var showSettings = false
    /// Whether the poof animation is active
    @Published var showPoofAnimation = false
    /// Opacity value for the poof animation
    @Published var poofOpacity: Double = 1.0

    /// Colors for the current theme + day/night mode.
    var colors: ThemeColors {
        theme.colors(for: colorMode)
    }

    /// Stealth stays dark so system chrome does not flip to light.
    var preferredColorScheme: ColorScheme {
        theme == .stealth ? .dark : colorMode.preferredColorScheme
    }

    init() {
        let defaults = UserDefaults.standard
        let savedMode = defaults.string(forKey: Self.colorModeDefaultsKey)
        let savedTheme = defaults.string(forKey: Self.themeDefaultsKey)

        // Old discreet lighting mode is now the Stealth theme.
        if savedMode == "discreet" {
            self.theme = .stealth
            self.colorMode = .night
            defaults.set(AppTheme.stealth.rawValue, forKey: Self.themeDefaultsKey)
            defaults.set(ColorMode.night.rawValue, forKey: Self.colorModeDefaultsKey)
        } else {
            self.theme = AppTheme(rawValue: savedTheme ?? "") ?? .grove
            self.colorMode = ColorMode(rawValue: savedMode ?? "") ?? .night
        }

        let savedFont = defaults.string(forKey: Self.fontChoiceDefaultsKey)
        // Dropped Didot / interim “sans”; map them to System.
        let migrated: String?
        switch savedFont {
        case "didot", "sans": migrated = AppFontChoice.system.rawValue
        default: migrated = savedFont
        }
        let resolvedFont = AppFontChoice(rawValue: migrated ?? "") ?? .system
        self.fontChoice = resolvedFont
        AppType.fontChoice = resolvedFont

        let savedName = defaults.string(forKey: Self.displayNameDefaultsKey)
        if let savedName, let normalized = P2PConfig.normalizedName(savedName) {
            self.displayName = normalized
        } else {
            self.displayName = Self.hostDisplayName()
        }
        if defaults.object(forKey: Self.relayMessagesDefaultsKey) == nil {
            self.relayMessages = true
        } else {
            self.relayMessages = defaults.bool(forKey: Self.relayMessagesDefaultsKey)
        }
        let savedKeepAlive = defaults.string(forKey: Self.radioKeepAliveDefaultsKey)
        self.radioKeepAlive = RadioKeepAlive(rawValue: savedKeepAlive ?? "") ?? .thirtyMinutes
        self.emojiDetectionEnabled = defaults.bool(forKey: Self.emojiDetectionDefaultsKey)
    }

    /// Device host name used until the user picks a display name.
    static func hostDisplayName() -> String {
        P2PConfig.normalizedName(UIDevice.current.name) ?? "ClosedCaptioner"
    }

    /// Empty or whitespace falls back to the host name.
    func commitDisplayName() {
        displayName = P2PConfig.normalizedName(displayName) ?? Self.hostDisplayName()
    }

    /// Clears the screen with a short poof animation (no flash overlay).
    func clearScreen() {
        startPoofAnimation()
    }

    /// Starts the poof animation that fades out over 0.8 seconds
    func startPoofAnimation() {
        showPoofAnimation = true
        poofOpacity = 1.0

        withAnimation(.easeOut(duration: 0.8)) {
            poofOpacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            self.showPoofAnimation = false
            self.poofOpacity = 1.0
        }
    }

    /// Toggles the keyboard editing view visibility
    func toggleKeyboard() {
        showKeyboard.toggle()
    }

    /// Opens or closes Settings
    func toggleSettings() {
        showSettings.toggle()
    }

    func closeSettings() {
        showSettings = false
    }
}
