//
//  AppStateViewModel.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

class AppStateViewModel: ObservableObject {
    @Published var colorMode: ColorMode = .night
    @Published var showKeyboard = false
    @Published var showFlash = false
    @Published var showPoofAnimation = false
    @Published var poofOpacity: Double = 1.0
    
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
    
    func clearScreen() {
        // Flash effect - white screen flash
        showFlash = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.showFlash = false
            self.startPoofAnimation()
        }
    }
    
    func startPoofAnimation() {
        showPoofAnimation = true
        poofOpacity = 1.0
        
        // Animate POOF disappearing over 0.8 seconds (much faster)
        withAnimation(.easeOut(duration: 0.8)) {
            poofOpacity = 0.0
        }
        
        // After animation completes, hide it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            self.showPoofAnimation = false
            self.poofOpacity = 1.0
        }
    }
    
    func toggleKeyboard() {
        showKeyboard.toggle()
    }
}

