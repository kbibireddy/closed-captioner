//
//  AppLog.swift
//  ClosedCaptioner
//

import Foundation
import OSLog

/// Debug-only logging. Release builds compile these calls out (autoclosure is not evaluated).
enum AppLog {
    private static let logger = Logger(subsystem: "RaveSociety.ClosedCaptioner", category: "app")

    static func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
        // Evaluate before Logger interpolation (OSLogMessage capture is escaping).
        let text = message()
        logger.log("\(text, privacy: .public)")
        #endif
    }
}
