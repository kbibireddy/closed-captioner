//
//  InstallGracePeriod.swift
//  ClosedCaptioner
//
//  First 30 days after install: no ads, Purchases tab hidden.
//

import Foundation

/// Calendar-day grace window from first install. Uses the Documents directory
/// creation date when available so upgrades keep the original install day;
/// otherwise records "now" once in UserDefaults.
enum InstallGracePeriod {
    static let durationDays = 30
    private static let defaultsKey = "ClosedCaptioner.installDate"

    /// First day the app existed on this device (persisted).
    static var installDate: Date {
        let defaults = UserDefaults.standard
        if let saved = defaults.object(forKey: defaultsKey) as? Date {
            return saved
        }
        let resolved = documentsDirectoryCreationDate() ?? Date()
        defaults.set(resolved, forKey: defaultsKey)
        return resolved
    }

    /// True while still inside the first `durationDays` after install.
    static var isActive: Bool {
        guard let end = Calendar.current.date(
            byAdding: .day,
            value: durationDays,
            to: installDate
        ) else {
            return false
        }
        return Date() < end
    }

    private static func documentsDirectoryCreationDate() -> Date? {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let created = attrs[.creationDate] as? Date else {
            return nil
        }
        return created
    }
}
