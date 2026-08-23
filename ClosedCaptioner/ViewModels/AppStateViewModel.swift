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
    private static let displayNameDefaultsKey = "ClosedCaptioner.displayName"
    private static let relayMessagesDefaultsKey = "ClosedCaptioner.relayMessages"
    private static let radioKeepAliveDefaultsKey = "ClosedCaptioner.radioKeepAlive"

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
    /// Nearby identity. Defaults to the device host name; user can set any name.
    @Published var displayName: String {
        didSet {
            UserDefaults.standard.set(displayName, forKey: Self.displayNameDefaultsKey)
        }
    }
    /// When radio is on, forward nearby captions to other neighbors. Default off.
    @Published var relayMessages: Bool {
        didSet {
            UserDefaults.standard.set(relayMessages, forKey: Self.relayMessagesDefaultsKey)
        }
    }
    /// Auto-off for radio (and relay) after this duration. Default 4 hours.
    @Published var radioKeepAlive: RadioKeepAlive {
        didSet {
            UserDefaults.standard.set(radioKeepAlive.rawValue, forKey: Self.radioKeepAliveDefaultsKey)
        }
    }
    /// Whether the keyboard editing view is visible
    @Published var showKeyboard = false
    /// Whether Settings (History / Purchases) is visible
    @Published var showSettings = false
    /// Whether the flash animation is active
    @Published var showFlash = false
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

        let savedName = defaults.string(forKey: Self.displayNameDefaultsKey)
        if let savedName, let normalized = P2PConfig.normalizedName(savedName) {
            self.displayName = normalized
        } else {
            self.displayName = Self.hostDisplayName()
        }
        self.relayMessages = defaults.bool(forKey: Self.relayMessagesDefaultsKey)
        let savedKeepAlive = defaults.string(forKey: Self.radioKeepAliveDefaultsKey)
        self.radioKeepAlive = RadioKeepAlive(rawValue: savedKeepAlive ?? "") ?? .fourHours
    }

    /// Device host name used until the user picks a display name.
    static func hostDisplayName() -> String {
        P2PConfig.normalizedName(UIDevice.current.name) ?? "ClosedCaptioner"
    }

    /// Empty or whitespace falls back to the host name.
    func commitDisplayName() {
        displayName = P2PConfig.normalizedName(displayName) ?? Self.hostDisplayName()
    }

    /// Clears the screen with a flash animation followed by a poof animation
    func clearScreen() {
        showFlash = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.showFlash = false
            self.startPoofAnimation()
        }
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
