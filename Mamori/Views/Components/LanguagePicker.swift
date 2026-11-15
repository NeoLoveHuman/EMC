import SwiftUI

struct LanguagePicker: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Menu {
            ForEach(L10n.languages) { lang in
                Button {
                    store.setLanguage(lang.code)
                } label: {
                    if lang.code == store.lang {
                        Label(lang.name, systemImage: "checkmark")
                    } else {
                        Text(lang.name)
                    }
                }
            }
        } label: {
            HStack(spacing: Theme.space1) {
                Image(systemName: "globe")
                    .accessibilityHidden(true)
                Text(L10n.short(store.lang))
                    .lineLimit(1)
                    .fixedSize()
            }
            .font(Theme.label)
            .foregroundStyle(Theme.ink)
            .frame(minWidth: Theme.minTap, minHeight: Theme.minTap)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(store.t("home_language") + ", " + currentName)
    }

    private var currentName: String {
        L10n.languages.first { $0.code == store.lang }?.name ?? store.lang
    }
}

/// Language picker (left) + bell with unread dot (right), on every tab.
struct MamoriToolbar: ViewModifier {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showAlerts = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    LanguagePicker()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    bellButton
                }
            }
            .sheet(isPresented: $showAlerts) {
                AlertsView().environment(store)
            }
    }

    /// Bell with a red count badge (a number, not just a dot), 44 pt target.
    private var bellButton: some View {
        let unread: Int = store.unreadAlerts
        let bounceValue: Int = reduceMotion ? 0 : unread
        let spoken: String = unread > 0
            ? store.t("alerts") + ", " + store.t("home_alerts_new", ["n": "\(unread)"])
            : store.t("alerts")
        return Button {
            showAlerts = true
        } label: {
            Image(systemName: "bell.fill")
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
                .symbolEffect(.bounce, value: bounceValue)
                .frame(width: Theme.minTap, height: Theme.minTap)
                .overlay(alignment: .topTrailing) {
                    if unread > 0 {
                        Text(verbatim: "\(unread)")
                            .font(Theme.badgeCount)
                            .foregroundStyle(Theme.onDark)
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.horizontal, 5)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(Theme.statusDanger, in: Capsule())
                            .offset(x: 2, y: 2)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .contentShape(Rectangle())
        }
        .accessibilityLabel(spoken)
    }
}

extension View {
    func mamoriToolbar() -> some View { modifier(MamoriToolbar()) }
}
