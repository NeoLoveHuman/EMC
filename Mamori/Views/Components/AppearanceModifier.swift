import SwiftUI

/// Light / dark override for the presenter. "system" (default) follows the phone's setting;
/// "light" and "dark" force one look. Set from the Demo panel, stored in UserDefaults.
struct MamoriAppearance: ViewModifier {
    @AppStorage(Theme.appearanceKey) private var appearance: String = "system"

    private var scheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    func body(content: Content) -> some View {
        content.preferredColorScheme(scheme)
    }
}

extension View {
    /// Apply once, at the root of the app.
    func mamoriAppearance() -> some View { modifier(MamoriAppearance()) }
}
