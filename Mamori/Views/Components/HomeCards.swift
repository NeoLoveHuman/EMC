import SwiftUI

// MARK: - Units: three small rings folded, one line per unit open

/// Folded: a small ring per unit with its letter and moisture.
/// Open: the farm total (concentric rings) and one tappable line per unit → that unit.
struct HomeUnitsCard: View {
    @Environment(AppStore.self) private var store
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        ExpandableCard(isExpanded: isExpanded, summary: spoken, onToggle: onToggle) {
            HomeUnitRings()
        } content: {
            HomeUnitsDetail()
        }
    }

    private var spoken: String {
        let now: Date = store.now
        var parts: [String] = [store.t("my_units")]
        for unit in store.state.units {
            let m: Double = Simulation.moisture(of: unit, at: now)
            let line: String = [store.t("unit", ["id": unit.id]),
                                store.t(unit.crop),
                                store.t("moisture") + " " + Fmt.percent1(m),
                                HomeUnitText.status(unit, now: now, store: store)].joined(separator: ", ")
            parts.append(line)
        }
        return parts.joined(separator: ". ")
    }
}

/// Status words shared by the folded and open unit rows.
enum HomeUnitText {
    @MainActor
    static func status(_ unit: Unit, now: Date, store: AppStore) -> String {
        let p: CropProfile = Simulation.profile(for: unit.crop)
        let day: Double = Simulation.day(since: unit.batchStart, at: now)
        switch unit.mode {
        case .storing:
            return store.t("in_storage_day", ["d": "\(p.storageDay(day))"])
        case .drying:
            if p.isDry(day) { return store.t("ready") }
            return store.t("day_of", ["d": "\(p.dayNumber(day))", "t": "\(Int(p.unitDays))"])
        }
    }

    @MainActor
    static func vents(_ unit: Unit, now: Date, store: AppStore) -> String {
        switch unit.ventDisplay(at: now) {
        case .open: return store.t("vent_open")
        case .closing: return store.t("vent_closing")
        case .closed: return store.t("vent_closed")
        }
    }
}

private struct HomeUnitRings: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let units: [Unit] = store.state.units
        let now: Date = store.now
        HStack(spacing: Theme.space2) {
            ForEach(units.indices, id: \.self) { index in
                if units.indices.contains(index) {
                    HomeMiniRing(unit: units[index], index: index, now: now)
                }
            }
        }
    }
}

private struct HomeMiniRing: View {
    let unit: Unit
    let index: Int
    let now: Date

    var body: some View {
        let moisture: Double = Simulation.moisture(of: unit, at: now)
        let progress: Double = Simulation.dryingProgress(moisture: moisture)
        let color: Color = Theme.unitRingColor(index)
        VStack(spacing: 2) {
            ZStack {
                ProgressRing(progress: progress, color: color, lineWidth: 5)
                Text(verbatim: unit.id)
                    .font(Theme.smallBold)
                    .foregroundStyle(Theme.ink)
            }
            .frame(width: 38, height: 38)
            Text(Fmt.percent1(moisture))
                .font(Theme.dashRingNumber)
                .foregroundStyle(Theme.wetnessColor(moisture))
                .lineLimit(1)
                .fixedSize()
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HomeUnitsDetail: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let units: [Unit] = store.state.units
        VStack(alignment: .leading, spacing: Theme.space2) {
            HomeFarmTotal()
            ForEach(units.indices, id: \.self) { index in
                if units.indices.contains(index) {
                    HomeUnitLine(unit: units[index], index: index)
                }
            }
        }
    }
}

/// The old hero, small: one ring per unit, nested, with the farm total beside it.
private struct HomeFarmTotal: View {
    @Environment(AppStore.self) private var store
    let size: CGFloat = 96
    let ringWidth: CGFloat = 8
    let gap: CGFloat = 3

    var body: some View {
        let units: [Unit] = store.state.units
        let now: Date = store.now
        let step: CGFloat = ringWidth + gap
        HStack(spacing: Theme.spacing) {
            ZStack {
                ForEach(units.indices, id: \.self) { index in
                    if units.indices.contains(index) {
                        ProgressRing(progress: progress(units[index], now: now),
                                     color: Theme.unitRingColor(index),
                                     lineWidth: ringWidth)
                            .padding(CGFloat(index) * step)
                    }
                }
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
            totals(count: units.count)
        }
        .accessibilityElement(children: .combine)
    }

    private func progress(_ unit: Unit, now: Date) -> Double {
        Simulation.dryingProgress(moisture: Simulation.moisture(of: unit, at: now))
    }

    private func totals(count: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Fmt.kg(store.state.totalWeightKg))
                .font(Theme.ringNumber)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .contentTransition(.numericText())
            Text(store.t("crop_protected"))
                .font(Theme.small)
                .foregroundStyle(Theme.inkStrong)
            Text(store.t("units_n", ["n": "\(count)"]))
                .font(Theme.small)
                .foregroundStyle(Theme.inkStrong)
        }
    }
}

/// One unit: crop, day x of y, moisture, vents. Tap → that unit (same as the old ring cells).
private struct HomeUnitLine: View {
    @Environment(AppStore.self) private var store
    let unit: Unit
    let index: Int

    var body: some View {
        let now: Date = store.now
        let moisture: Double = Simulation.moisture(of: unit, at: now)
        let name: String = store.t("unit", ["id": unit.id]) + " · " + store.t(unit.crop)
        let status: String = HomeUnitText.status(unit, now: now, store: store)
        let vents: String = HomeUnitText.vents(unit, now: now, store: store)
        let moistureText: String = store.t("moisture") + " " + Fmt.percent1(moisture)
        let detail: String = [status, moistureText, vents].joined(separator: " · ")
        let dot: Color = Theme.unitRingColor(index)
        Button {
            store.openUnit(unit.id)
        } label: {
            HStack(spacing: Theme.space3) {
                Circle()
                    .fill(dot)
                    .frame(width: 14, height: 14)
                    .overlay { Circle().stroke(Theme.hairline, lineWidth: 1) }
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(Theme.label)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(detail)
                        .font(Theme.small)
                        .foregroundStyle(Theme.inkStrong)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Theme.space1)
                Image(systemName: "chevron.right")
                    .font(Theme.label)
                    .foregroundStyle(Theme.inkStrong)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Theme.space3)
            .padding(.vertical, Theme.space2)
            .frame(maxWidth: .infinity, minHeight: Theme.minTap, alignment: .leading)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name + ", " + detail)
        .accessibilityHint(store.t("home_open_unit"))
    }
}

// MARK: - Price and advice

/// Folded: ₹15,600, +20% vs last week, HOLD / SELL pill.
/// Open: the advice sentence, the reasons list, batch worth, and a jump to Network.
struct HomePriceCard: View {
    @Environment(AppStore.self) private var store
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        ExpandableCard(isExpanded: isExpanded, summary: spoken, onToggle: onToggle) {
            HomePriceRow()
        } content: {
            HomePriceDetail()
        }
    }

    private var spoken: String {
        let change: String = Fmt.signedPercent(store.state.priceChangePercent)
        let advice: String = store.t(store.state.advice == .sell ? "sell" : "hold")
        return [store.t("market_today"),
                Fmt.rupees(store.state.pricePer100kg) + " " + store.t("per_100kg"),
                store.t("vs_last_week", ["p": change]),
                advice,
                store.adviceSentence].joined(separator: ". ")
    }
}

private struct HomePriceRow: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let change: Int = store.state.priceChangePercent
        let up: Bool = change >= 0
        let changeColor: Color = up ? Theme.good : Theme.danger
        let changeText: String = store.t("vs_last_week", ["p": Fmt.signedPercent(change)])
        HStack(alignment: .center, spacing: Theme.space3) {
            Image(systemName: "indianrupeesign.circle.fill")
                .font(Theme.sectionTitle)
                .foregroundStyle(changeColor)
                .frame(width: HomeStyle.iconWidth)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(Fmt.rupees(store.state.pricePer100kg))
                    .font(HomeStyle.rowNumber)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Text(changeText)
                    .font(Theme.smallBold)
                    .foregroundStyle(changeColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Theme.space1)
            HomeAdvicePill()
        }
    }
}

/// HOLD (dark pill) or SELL (lime pill). Ink + background invert together in dark mode.
struct HomeAdvicePill: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let isSell: Bool = store.state.advice == .sell
        let fill: Color = isSell ? Theme.accent : Theme.ink
        let text: Color = isSell ? Theme.onAccent : Theme.background
        let symbol: String = isSell ? "checkmark" : "hand.raised.fill"
        Label(store.t(isSell ? "sell" : "hold"), systemImage: symbol)
            .font(Theme.headline)
            .foregroundStyle(text)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, Theme.space3)
            .padding(.vertical, Theme.space2)
            .background(fill, in: Capsule())
    }
}

private struct HomePriceDetail: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space3) {
            Text(store.t("market_today") + " · " + store.t("per_100kg"))
                .font(Theme.small)
                .foregroundStyle(Theme.inkStrong)
            Text(store.adviceSentence)
                .font(Theme.dynHeadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            ReasonList()
            worthRow
            HomeActionButton(title: store.t("home_go_sell"), symbol: "arrow.right") {
                store.selectedTab = .network
            }
        }
    }

    private var worthRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.space2) {
            Text(store.t("worth"))
                .font(Theme.small)
                .foregroundStyle(Theme.inkStrong)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Theme.space2)
            Text(Fmt.rupees(store.homeUnitAWorth))
                .font(Theme.ringNumber)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.numericText())
                .layoutPriority(1)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Field (Mamori Eye add-on)

/// Folded: "Field view · Mamori Eye add-on" and 62%. Open: the field card content.
struct HomeFieldCard: View {
    @Environment(AppStore.self) private var store
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        let pct: Int = Simulation.fieldEfficiencyPercent
        let spoken: String = [store.t("field_view"), store.t("addon"),
                              store.t("field_eff", ["p": "\(pct)"]),
                              store.t("field_missed")].joined(separator: ". ")
        ExpandableCard(isExpanded: isExpanded, summary: spoken, onToggle: onToggle) {
            HomeRowHeader(symbol: "dot.radiowaves.left.and.right", iconColor: Theme.ink,
                          title: store.t("field_view"), subtitle: store.t("addon"),
                          value: "\(pct)%", caption: nil,
                          ink: Theme.ink, muted: Theme.inkStrong, valueColor: Theme.warn)
        } content: {
            FieldDetail()
        }
    }
}
