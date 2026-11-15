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

    /// Red when rain is coming, lime when the advice is SELL, green otherwise.
    var homeStatusLevel: HomeStatusLevel {
        if rainMinutesLeft(at: now) != nil { return .rain }
        if state.advice == .sell { return .sell }
        return .safe
    }

    /// A unit's crop can be sold now: it is in storage, or it has finished drying.
    func homeIsSellable(_ unit: Unit) -> Bool {
        if unit.mode == .storing { return true }
        let day: Double = Simulation.day(since: unit.batchStart, at: now)
        return Simulation.profile(for: unit.crop).isDry(day)
    }

    var homeSellableUnits: [Unit] { state.units.filter { homeIsSellable($0) } }

    /// Weight × today's Guntur price.
    func homeWorth(_ unit: Unit) -> Int { unit.weightKg * state.pricePer100kg / 100 }

    var homeSellableWorth: Int { homeSellableUnits.reduce(0) { $0 + homeWorth($1) } }

    /// Bags in a unit: the stored count, or weight / 40 kg for a batch just dried.
    func homeBags(_ unit: Unit) -> Int {
        unit.bags ?? unit.weightKg / max(1, Simulation.kgPerBag)
    }

    /// Market paying the most after transport (Guntur with the seed numbers).
    var homeBestMarket: Market? {
        let price: Int = state.pricePer100kg
        return Simulation.markets.max { a, b in
            Simulation.netPricePer100kg(market: a, livePrice: price)
                < Simulation.netPricePer100kg(market: b, livePrice: price)
        }
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

// MARK: - Top of Home: is my crop safe, what happens next, what can I sell

enum HomeStatusLevel: Equatable {
    case safe, sell, rain
}

/// Folded: "All safe · Unit A dry in 2 days" and Unit A's worth.
/// Open: what happens next per unit, then what is ready to sell (sell block first on SELL,
/// rain block first when rain is coming).
struct HomeStatusCard: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        let level: HomeStatusLevel = store.homeStatusLevel
        let fill: Color = Self.fill(level)
        let ink: Color = Self.ink(level)
        let levelAnimation: Animation? = Theme.motion(Theme.motionQuick, reduce: reduceMotion)
        ExpandableCard(isExpanded: isExpanded, summary: spoken(level), fill: fill, ink: ink,
                       onToggle: onToggle) {
            folded(level: level, ink: ink)
        } content: {
            HomeStatusDetail(level: level, ink: ink)
        }
        .animation(levelAnimation, value: level)
    }

    static func fill(_ level: HomeStatusLevel) -> Color {
        switch level {
        case .safe: return Theme.statusSafe
        case .sell: return Theme.accent
        case .rain: return Theme.statusDanger
        }
    }

    static func ink(_ level: HomeStatusLevel) -> Color {
        level == .sell ? Theme.onAccent : Theme.onDark
    }

    private func symbol(_ level: HomeStatusLevel) -> String {
        switch level {
        case .safe: return "checkmark.shield.fill"
        case .sell: return "indianrupeesign.circle.fill"
        case .rain: return "cloud.heavyrain.fill"
        }
    }

    private func title(_ level: HomeStatusLevel) -> String {
        switch level {
        case .safe: return store.t("home_status_safe")
        case .sell: return store.t("home_status_sell")
        case .rain: return store.t("alert_rain_title")
        }
    }

    private func subtitle(_ level: HomeStatusLevel) -> String {
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

    /// Key number on the right: minutes to rain, sellable worth, or Unit A's worth.
    private func value(_ level: HomeStatusLevel) -> String {
        switch level {
        case .rain:
            let mins: Int = store.rainMinutesLeft(at: store.now) ?? 0
            return "\(mins) min"
        case .sell: return Fmt.rupees(store.homeSellableWorth)
        case .safe: return Fmt.rupees(store.homeUnitAWorth)
        }
    }

    private func caption(_ level: HomeStatusLevel) -> String {
        switch level {
        case .rain: return store.t("home_until_rain")
        case .sell: return store.t("home_ready_sell")
        case .safe: return store.t("home_worth_caption", ["id": store.unitA.id])
        }
    }

    private func folded(level: HomeStatusLevel, ink: Color) -> some View {
        HomeRowHeader(symbol: symbol(level), iconColor: ink,
                      title: title(level), subtitle: subtitle(level),
                      value: value(level), caption: caption(level),
                      ink: ink, muted: ink)
    }

    private func spoken(_ level: HomeStatusLevel) -> String {
        var parts: [String] = [title(level), subtitle(level)]
        switch level {
        case .rain:
            let mins: Int = store.rainMinutesLeft(at: store.now) ?? 0
            parts.append(store.t("rain_in", ["n": "\(mins)"]))
        case .sell:
            parts.append(store.t("home_ready_sell") + " " + Fmt.rupees(store.homeSellableWorth))
        case .safe:
            parts.append(store.t("home_worth", ["id": store.unitA.id]) + " " + Fmt.rupees(store.homeUnitAWorth))
        }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Open status card

struct HomeStatusDetail: View {
    @Environment(AppStore.self) private var store
    let level: HomeStatusLevel
    let ink: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space3) {
            if level == .rain {
                HomeRainBlock(ink: ink)
            }
            if level == .sell {
                HomeSellBlock(ink: ink)
                HomeNextList(ink: ink)
            } else {
                HomeNextList(ink: ink)
                HomeSellBlock(ink: ink)
            }
        }
    }
}

/// Rain coming: countdown and which vents shut.
struct HomeRainBlock: View {
    @Environment(AppStore.self) private var store
    let ink: Color

    var body: some View {
        let mins: Int = store.rainMinutesLeft(at: store.now) ?? 0
        let closed: String = store.homeClosedVentUnits
        let ventLine: String = closed.isEmpty ? store.t("drying_bad") : store.t("rain_vents", ["u": closed])
        let tint: Color = ink.opacity(0.16)
        VStack(alignment: .leading, spacing: Theme.space2) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.space2) {
                Text(verbatim: "\(mins) min")
                    .font(Theme.bigNumber)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Text(store.t("home_until_rain"))
                    .font(Theme.label)
                    .lineLimit(2)
            }
            Label(ventLine, systemImage: "lock.fill")
                .font(Theme.dynLabel)
                .fixedSize(horizontal: false, vertical: true)
            Text(store.t("closed_auto"))
                .font(Theme.small)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(ink)
        .padding(Theme.space3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
        .accessibilityElement(children: .combine)
    }
}

/// "What happens next": one numbered line per unit.
struct HomeNextList: View {
    @Environment(AppStore.self) private var store
    let ink: Color

    var body: some View {
        let units: [Unit] = store.state.units
        VStack(alignment: .leading, spacing: Theme.space2) {
            HomeSubheading(text: store.t("home_next"), symbol: "list.number", color: ink)
            ForEach(Array(units.enumerated()), id: \.element.id) { pair in
                HomeNextRow(number: pair.offset + 1, unit: pair.element, ink: ink)
            }
        }
    }
}

struct HomeNextRow: View {
    @Environment(AppStore.self) private var store
    let number: Int
    let unit: Unit
    let ink: Color

    var body: some View {
        let fill: Color = ink.opacity(0.16)
        HStack(alignment: .top, spacing: Theme.space3) {
            Text(verbatim: "\(number)")
                .font(Theme.smallBold)
                .foregroundStyle(ink)
                .frame(width: 28, height: 28)
                .background(fill, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.space1) {
                Text(line)
                    .font(Theme.dynLabel)
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
                progressBar
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var progressBar: some View {
        if let fraction = dayFraction {
            ProgressView(value: fraction)
                .tint(ink)
                .accessibilityHidden(true)
        }
    }

    /// Drying units only: how far through the drying days (0...1).
    private var dayFraction: Double? {
        guard unit.mode == .drying else { return nil }
        let p: CropProfile = Simulation.profile(for: unit.crop)
        guard p.unitDays > 0 else { return nil }
        let day: Double = Simulation.day(since: unit.batchStart, at: store.now)
        return min(1, max(0, day / p.unitDays))
    }

    private var line: String {
        let p: CropProfile = Simulation.profile(for: unit.crop)
        let day: Double = Simulation.day(since: unit.batchStart, at: store.now)
        let name: String = store.t("unit", ["id": unit.id]) + " · " + store.t(unit.crop)
        switch unit.mode {
        case .storing:
            return store.t("home_next_stored", [
                "u": name,
                "b": "\(store.homeBags(unit))",
                "kg": Fmt.kg(unit.weightKg)
            ])
        case .drying:
            if p.isDry(day) { return store.t("home_next_ready", ["u": name]) }
            let left: Int = p.daysLeft(day)
            let args: [String: String] = [
                "u": name,
                "d": "\(p.dayNumber(day))",
                "t": "\(Int(p.unitDays))",
                "n": "\(left)"
            ]
            return store.t(left >= 2 ? "home_next_drying" : "home_next_soon", args)
        }
    }
}

/// "Ready to sell": what is sellable now, its worth today, best market, jump to Network.
struct HomeSellBlock: View {
    @Environment(AppStore.self) private var store
    let ink: Color

    var body: some View {
        let units: [Unit] = store.homeSellableUnits
        let tint: Color = ink.opacity(0.16)
        VStack(alignment: .leading, spacing: Theme.space2) {
            HomeSubheading(text: store.t("home_ready_sell"), symbol: "bag.fill", color: ink)
            if units.isEmpty {
                Text(store.t("home_nothing_ready"))
                    .font(Theme.dynLabel)
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(units) { unit in
                    sellRow(unit)
                }
                totalRow
            }
            priceLine
            marketLine
            HomeActionButton(title: store.t("home_go_sell"), symbol: "arrow.right") {
                store.selectedTab = .network
            }
            .padding(.top, Theme.space1)
        }
        .padding(Theme.space3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
    }

    private func sellRow(_ unit: Unit) -> some View {
        let name: String = store.t("unit", ["id": unit.id]) + " · " + store.t(unit.crop)
        let detail: String = store.t("bags", ["n": "\(store.homeBags(unit))"]) + " · " + Fmt.kg(unit.weightKg)
        let worth: String = Fmt.rupees(store.homeWorth(unit))
        return HStack(alignment: .firstTextBaseline, spacing: Theme.space2) {
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(Theme.label)
                Text(detail)
                    .font(Theme.small)
            }
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Theme.space2)
            Text(worth)
                .font(Theme.headline)
                .lineLimit(1)
                .layoutPriority(1)
        }
        .foregroundStyle(ink)
        .accessibilityElement(children: .combine)
    }

    private var totalRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.space2) {
            Text(store.t("home_worth_total"))
                .font(Theme.small)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Theme.space2)
            Text(Fmt.rupees(store.homeSellableWorth))
                .font(Theme.ringNumber)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.numericText())
                .layoutPriority(1)
        }
        .foregroundStyle(ink)
        .accessibilityElement(children: .combine)
    }

    private var priceLine: some View {
        let price: String = Fmt.rupees(store.state.pricePer100kg)
        let change: String = Fmt.signedPercent(store.state.priceChangePercent)
        let text: String = store.t("home_price_line", ["v": price, "p": change])
        return Text(text)
            .font(Theme.small)
            .foregroundStyle(ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var marketLine: some View {
        if let market = store.homeBestMarket {
            let net: Int = Simulation.netPricePer100kg(market: market, livePrice: store.state.pricePer100kg)
            let text: String = store.t("home_best_market", [
                "m": store.t(market.nameKey),
                "k": store.t("km", ["n": "\(market.distanceKm)"]),
                "net": store.t("net_price", ["v": Fmt.rupees(net)])
            ])
            Label(text, systemImage: "mappin.and.ellipse")
                .font(Theme.label)
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
