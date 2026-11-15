import SwiftUI

// MARK: - Read-only helpers for the home screen (no new state, nothing stored)

extension AppStore {
    /// Days until Unit A is dry, from its own crop profile.
    var homeUnitADaysLeft: Int {
        let unit: Unit = unitA
        let day: Double = Simulation.day(since: unit.batchStart, at: now)
        return Simulation.profile(for: unit.crop).daysLeft(day)
    }

    var homeUnitAIsDry: Bool {
        let unit: Unit = unitA
        let day: Double = Simulation.day(since: unit.batchStart, at: now)
        return Simulation.profile(for: unit.crop).isDry(day)
    }

    /// Same sum the voice answer says ("worth about ₹156,000"): Unit A weight × today's price.
    var homeUnitAWorth: Int {
        unitA.weightKg * state.pricePer100kg / 100
    }

    /// Drying units whose vents are shut, e.g. "A, C".
    var homeClosedVentUnits: String {
        state.units
            .filter { $0.mode == .drying && $0.vent == .closed }
            .map { $0.id }
            .joined(separator: ", ")
    }
}

/// Small consistent title used at the top of every card I own.
struct MamoriCardTitle: View {
    let text: String
    let symbol: String
    var color: Color = Theme.inkStrong

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: symbol)
                .accessibilityHidden(true)
        }
        .font(Theme.label)
        .foregroundStyle(color)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}

// MARK: - Top of Home: is my crop safe, when is it dry, what is it worth

enum HomeStatusLevel: Equatable {
    case safe, sell, rain
}

struct HomeStatusCard: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var level: HomeStatusLevel {
        if store.rainMinutesLeft(at: store.now) != nil { return .rain }
        if store.state.advice == .sell { return .sell }
        return .safe
    }

    private var fill: Color {
        switch level {
        case .safe: return Theme.statusSafe
        case .sell: return Theme.accent
        case .rain: return Theme.statusDanger
        }
    }

    private var ink: Color {
        level == .sell ? Theme.onAccent : Theme.onDark
    }

    private var symbol: String {
        switch level {
        case .safe: return "checkmark.shield.fill"
        case .sell: return "indianrupeesign.circle.fill"
        case .rain: return "cloud.heavyrain.fill"
        }
    }

    private var title: String {
        switch level {
        case .safe: return store.t("home_status_safe")
        case .sell: return store.t("home_status_sell")
        case .rain:
            let mins: Int = store.rainMinutesLeft(at: store.now) ?? 0
            return store.t("rain_in", ["n": "\(mins)"])
        }
    }

    private var subtitle: String {
        if level == .rain {
            let closed: String = store.homeClosedVentUnits
            if closed.isEmpty { return store.t("drying_bad") }
            return store.t("rain_vents", ["u": closed])
        }
        let id: String = store.unitA.id
        if store.homeUnitAIsDry { return store.t("home_dry_done", ["id": id]) }
        let left: Int = store.homeUnitADaysLeft
        if left >= 2 { return store.t("home_dry_in", ["id": id, "d": "\(left)"]) }
        return store.t("home_dry_soon", ["id": id])
    }

    private var worthLabel: String {
        store.t("home_worth", ["id": store.unitA.id])
    }

    private var worthValue: String {
        Fmt.rupees(store.homeUnitAWorth)
    }

    private var spoken: String {
        [title, subtitle, worthLabel + " " + worthValue].joined(separator: ". ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space3) {
            headline
            Rectangle()
                .fill(ink.opacity(0.35))
                .frame(height: 1)
                .accessibilityHidden(true)
            worthRow
        }
        .card(fill: fill)
        .animation(Theme.motion(Theme.motionQuick, reduce: reduceMotion), value: level)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private var headline: some View {
        HStack(alignment: .top, spacing: Theme.space3) {
            Image(systemName: symbol)
                .font(Theme.sectionTitle)
                .foregroundStyle(ink)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.space1) {
                Text(title)
                    .font(Theme.statusTitle)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(Theme.dynHeadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(ink)
            Spacer(minLength: 0)
        }
    }

    private var worthRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.space2) {
            Text(worthLabel)
                .font(Theme.small)
                .foregroundStyle(ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Spacer(minLength: Theme.space2)
            Text(worthValue)
                .font(Theme.bigNumber)
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
                .layoutPriority(1)
        }
    }
}
