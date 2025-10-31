//
//  AppStateViewModel.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

/// View model that manages application state including UI modes and animations
class AppStateViewModel: ObservableObject {
    /// Current color mode (day, night, or discreet)
    @Published var colorMode: ColorMode = .night
    /// Whether the keyboard editing view is visible
    @Published var showKeyboard = false
    /// Whether the history view is visible
    @Published var showHistory = false
    /// Whether the flash animation is active
    @Published var showFlash = false
    /// Whether the poof animation is active
    @Published var showPoofAnimation = false
    /// Opacity value for the poof animation
    @Published var poofOpacity: Double = 1.0
    
    /// Cycles through color modes: day -> night -> discreet -> day
    func toggleColorMode() {
        switch colorMode {
        case .day:
            colorMode = .night
        case .night:
            colorMode = .discreet
        case .discreet:
            colorMode = .day
        }
    }
    
    /// Clears the screen with a flash animation followed by a poof animation
    func clearScreen() {
        // Flash effect - white screen flash
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
        
        // Animate POOF disappearing over 0.8 seconds
        withAnimation(.easeOut(duration: 0.8)) {
            poofOpacity = 0.0
        }
        
        // After animation completes, hide it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            self.showPoofAnimation = false
            self.poofOpacity = 1.0
        }
    }
    
    /// Toggles the keyboard editing view visibility
    func toggleKeyboard() {
        showKeyboard.toggle()
    }
    
    /// Toggles the history view visibility
    func toggleHistory() {
        showHistory.toggle()
    }
}

