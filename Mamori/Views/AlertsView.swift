import SwiftUI

struct AlertsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How many of the newest alerts were unread when the sheet opened (newest first).
    @State private var unreadCount: Int = 0

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(store.t("alerts"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(store.t("done")) { dismiss() }
                            .font(Theme.label)
                    }
                }
        }
        .onAppear { markRead() }
        // An alert that arrives while the sheet is open shows up as new, then counts as seen.
        .onChange(of: store.unreadAlerts) { _, newValue in
            guard newValue > 0 else { return }
            markRead()
        }
    }

    @ViewBuilder
    private var content: some View {
        let alerts: [AlertItem] = store.state.alerts
        if alerts.isEmpty {
            emptyState
        } else {
            List {
                ForEach(Array(alerts.enumerated()), id: \.element.id) { pair in
                    MamoriAlertRow(alert: pair.element, isNew: pair.offset < unreadCount)
                        .listRowBackground(pair.offset < unreadCount ? Theme.unreadRow : Theme.background)
                        .listRowInsets(EdgeInsets(top: Theme.space3, leading: Theme.padding,
                                                  bottom: Theme.space3, trailing: Theme.padding))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .animation(Theme.motion(Theme.motionQuick, reduce: reduceMotion), value: alerts.count)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.space3) {
            Image(systemName: "bell.slash.fill")
                .font(Theme.weatherIcon)
                .foregroundStyle(Theme.good)
                .accessibilityHidden(true)
            Text(store.t("home_alerts_empty_title"))
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
            Text(store.t("home_alerts_empty_body"))
                .font(Theme.dynBody)
                .foregroundStyle(Theme.inkStrong)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func markRead() {
        unreadCount += store.unreadAlerts
        store.unreadAlerts = 0
    }
}

/// One alert: coloured icon per kind, title, body, relative time, and a "New" pill.
struct MamoriAlertRow: View {
    @Environment(AppStore.self) private var store
    let alert: AlertItem
    let isNew: Bool

    var body: some View {
        let style: MamoriAlertStyle = MamoriAlertStyle(kind: alert.kind)
        HStack(alignment: .top, spacing: Theme.spacing) {
            Image(systemName: alert.kind.symbol)
                .font(Theme.headline)
                .foregroundStyle(style.ink)
                .frame(width: Theme.minTap, height: Theme.minTap)
                .background(style.fill, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.space1) {
                titleRow
                Text(bodyText)
                    .font(Theme.dynBody)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(timeText)
                    .font(Theme.small)
                    .foregroundStyle(Theme.inkStrong)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private var titleRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.space2) {
            Text(store.t(alert.kind.titleKey))
                .font(Theme.dynHeadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if isNew {
                Text(store.t("home_new"))
                    .font(Theme.smallBold)
                    .foregroundStyle(Theme.onDark)
                    .lineLimit(1)
                    .padding(.horizontal, Theme.space2)
                    .padding(.vertical, 2)
                    .background(Theme.statusDanger, in: Capsule())
            }
        }
    }

    private var bodyText: String {
        store.t(alert.kind.bodyKey, ["v": Fmt.rupees(alert.value ?? 0)])
    }

    private var timeText: String {
        let f = RelativeDateTimeFormatter()
        f.locale = L10n.locale(store.lang)
        f.unitsStyle = .full
        return f.localizedString(for: alert.date, relativeTo: store.now)
    }

    private var spoken: String {
        var parts: [String] = []
        if isNew { parts.append(store.t("home_new")) }
        parts.append(store.t(alert.kind.titleKey))
        parts.append(bodyText)
        parts.append(timeText)
        return parts.joined(separator: ". ")
    }
}

/// Colour per alert kind. The icon shape and the title carry the meaning too, never colour alone.
struct MamoriAlertStyle {
    let fill: Color
    let ink: Color

    init(kind: AlertKind) {
        switch kind {
        case .rain:
            fill = Theme.rain; ink = Theme.onDark
        case .almostDry:
            fill = Theme.good; ink = Theme.onDark
        case .priceJump, .priceTarget:
            fill = Theme.accent; ink = Theme.onAccent
        case .dryingStarted:
            fill = Theme.ink; ink = Theme.onDark
        case .storageCheck:
            fill = Theme.statusSafe; ink = Theme.onDark
        }
    }
}
