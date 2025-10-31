//
//  ClosedCaptionerApp.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/26/25.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

@main
struct ClosedCaptionerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}
