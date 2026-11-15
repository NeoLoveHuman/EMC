import Foundation
import WidgetKit

/// Reads and writes SharedState through the App Group so the app and the
/// widget see the same data. The app's observable model is AppStore
/// (Mamori/Services/AppStore.swift); this file is shared with the widget.
///
/// Fallback: if the App Group cannot be provisioned on the free account,
/// remove the capability. The widget then finds nothing here and shows the
/// seed state (always "day 12"), which is the fallback in spec section 6.
enum SharedStore {
    static let appGroupID = "group.com.vasistha.mamori"
    static let stateKey = "mamori.sharedState.v3"

    /// True only when the App Group is really provisioned. UserDefaults(suiteName:)
    /// never returns nil, so a missing App Group would otherwise fail silently and
    /// the widget would not follow the app.
    static var isShared: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func load() -> SharedState? {
        guard let data = defaults.data(forKey: stateKey) else { return nil }
        return try? JSONDecoder().decode(SharedState.self, from: data)
    }

    static func save(_ state: SharedState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: stateKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
