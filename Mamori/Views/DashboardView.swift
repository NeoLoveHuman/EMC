import SwiftUI

/// First screen: the whole farm at a glance, as rings, with voice on top.
struct DashboardView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacing) {
                    header
                    // First two seconds: is my crop safe, when is it dry, what is it worth.
                    HomeStatusCard()
                    WeatherCard()
                    hero
                    unitRow
                    statRow
                    todayCard
                    FieldCard()
                }
                .padding(Theme.padding)
                .padding(.bottom, Theme.scrollBottomInset)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .mamoriToolbar()
        }
    }

    // MARK: Header (hidden: triple-tap opens the demo panel)

    private var header: some View {
        HStack(alignment: .center, spacing: Theme.space3) {
            Image("MamoriLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: Theme.space3))
                .accessibilityHidden(true)
            Text(verbatim: "Mamori")
                .font(Theme.screenTitle)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Text(verbatim: "守り")
                .font(Theme.screenTitle)
                .foregroundStyle(Theme.inkMuted)
                .accessibilityHidden(true)
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 3) { store.showDemoPanel = true }
    }

    // MARK: Hero: concentric rings, one per unit

    private var hero: some View {
        let units = store.state.units
        let now = store.now
        let step = Theme.heroRingWidth + Theme.heroRingGap
        let inner = Theme.heroRingSize - 2 * CGFloat(units.count) * step

        return ZStack {
            ForEach(units.indices, id: \.self) { index in
                ProgressRing(progress: heroProgress(units[index], now: now),
                             color: Theme.unitRingColor(index),
                             lineWidth: Theme.heroRingWidth)
                    .padding(CGFloat(index) * step)
            }
            VStack(spacing: 2) {
                Text(Fmt.kg(store.state.totalWeightKg))
                    .font(Theme.ringNumber)
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                Text(store.t("crop_protected"))
                    .font(Theme.small)
                    .foregroundStyle(Theme.inkStrong)
                Text(store.t("units_n", ["n": "\(units.count)"]))
                    .font(Theme.small)
                    .foregroundStyle(Theme.inkStrong)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .frame(width: max(60, inner - 12))
        }
        .frame(width: Theme.heroRingSize, height: Theme.heroRingSize)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(heroLabel)
    }

    private func heroProgress(_ unit: Unit, now: Date) -> Double {
        Simulation.dryingProgress(moisture: Simulation.moisture(of: unit, at: now))
    }

    private var heroLabel: String {
        let weight: String = Fmt.kg(store.state.totalWeightKg)
        let protected: String = store.t("crop_protected")
        let count: String = store.t("units_n", ["n": "\(store.state.units.count)"])
        return [weight, protected, count].joined(separator: ", ")
    }

    // MARK: One small ring per unit (tap → that unit)

    private var unitRow: some View {
        let now: Date = store.now
        let units: [Unit] = store.state.units
        return HStack(alignment: .top, spacing: Theme.space2) {
            ForEach(units.indices, id: \.self) { index in
                unitCell(index: index, unit: units[index], now: now)
            }
        }
        .card()
    }

    private func unitCell(index: Int, unit: Unit, now: Date) -> some View {
        let moisture: Double = Simulation.moisture(of: unit, at: now)
        let name: String = store.t("unit", ["id": unit.id])
        let crop: String = store.t(unit.crop)
        let status: String = shortStatus(unit, now: now)
        let mode: String = store.t(unit.mode == .drying ? "mode_drying" : "mode_storing")
        let moistureText: String = store.t("moisture") + " " + Fmt.percent1(moisture)
        let spoken: String = [name, crop, mode, status, moistureText].joined(separator: ", ")
        let dot: Color = Theme.unitRingColor(index)

        return Button {
            store.openUnit(unit.id)
        } label: {
            VStack(spacing: Theme.space1) {
                MoistureRing(moisture: moisture,
                             size: 92,
                             lineWidth: 9,
                             showTargetMarker: false,
                             numberFont: Theme.dashRingNumber,
                             animateOnAppear: true)
                    .padding(.bottom, Theme.space1)
                HStack(spacing: 6) {
                    Circle()
                        .fill(dot)
                        .frame(width: 12, height: 12)
                    Text(name)
                        .font(Theme.label)
                        .foregroundStyle(Theme.ink)
                }
                Text(crop)
                    .font(Theme.small)
                    .foregroundStyle(Theme.inkStrong)
                Text(status)
                    .font(Theme.smallBold)
                    .foregroundStyle(Theme.ink)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, minHeight: Theme.minTap)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
        .accessibilityHint(store.t("home_open_unit"))
        .accessibilityAddTraits(.isButton)
    }

    private func shortStatus(_ unit: Unit, now: Date) -> String {
        let p = Simulation.profile(for: unit.crop)
        let day = Simulation.day(since: unit.batchStart, at: now)
        switch unit.mode {
        case .storing: return store.t("mode_storing")
        case .drying:
            return p.isDry(day) ? store.t("ready")
                                : store.t("day_of", ["d": "\(p.dayNumber(day))", "t": "\(Int(p.unitDays))"])
        }
    }

    // MARK: Stat circles: price and advice (weather has its own card above)

    private var statRow: some View {
        let isSell: Bool = store.state.advice == .sell
        let change: Int = store.state.priceChangePercent

        let priceValue: String = Fmt.int(store.state.pricePer100kg)
        let priceCaption: String = store.t("per_100kg") + " · " + Fmt.signedPercent(change) + "%"
        let adviceSymbol: String = isSell ? "checkmark" : "hand.raised.fill"
        let adviceValue: String = store.t(isSell ? "sell" : "hold")
        let adviceFill: Color = isSell ? Theme.accent : Theme.ink
        let adviceInk: Color = isSell ? Theme.onAccent : Theme.onDark
        let priceInk: Color = change >= 0 ? Theme.good : Theme.danger

        return HStack(alignment: .top, spacing: Theme.space2) {
            Button {
                store.selectedTab = .network
            } label: {
                StatCircle(symbol: "indianrupeesign", value: priceValue, caption: priceCaption,
                           fill: Theme.surface, foreground: priceInk)
            }
            .buttonStyle(.plain)

            Button {
                store.selectedTab = .network
            } label: {
                StatCircle(symbol: adviceSymbol, value: adviceValue, caption: store.t("today"),
                           fill: adviceFill, foreground: adviceInk)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Today: advice and the reasons behind it

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: Theme.space2) {
            MamoriCardTitle(text: store.t("today"), symbol: "calendar")
            Text(store.adviceSentence)
                .font(Theme.dynHeadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            ReasonList()
        }
        .card()
    }

}

// MARK: - Why: the facts behind the advice

struct ReasonList: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let warning: String? = rainReason
        VStack(alignment: .leading, spacing: 6) {
            Text(store.t("why"))
                .font(Theme.small)
                .foregroundStyle(Theme.inkStrong)
            ForEach(store.adviceReasons, id: \.self) { reason in
                row(reason, isWarning: reason == warning)
            }
        }
    }

    /// The rain line gets a red warning icon, not a green tick.
    private var rainReason: String? {
        guard let mins = store.rainMinutesLeft(at: store.now) else { return nil }
        return store.t("rain_in", ["n": "\(mins)"])
    }

    private func row(_ reason: String, isWarning: Bool) -> some View {
        let symbol: String = isWarning ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
        let tint: Color = isWarning ? Theme.danger : Theme.good
        return HStack(alignment: .firstTextBaseline, spacing: Theme.space2) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(reason)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(Theme.dynLabel)
    }
}

// MARK: - Mamori Eye: one field card (add-on)

struct FieldCard: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space2) {
            HStack {
                MamoriCardTitle(text: store.t("field_view"), symbol: "dot.radiowaves.left.and.right")
                Spacer(minLength: Theme.space2)
                Text(store.t("addon"))
                    .font(Theme.small)
                    .foregroundStyle(Theme.onDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.ink, in: Capsule())
            }
            Text(store.t("field_eff", ["p": "\(Simulation.fieldEfficiencyPercent)"]))
                .font(Theme.dynHeadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Label(store.t("field_missed"), systemImage: "exclamationmark.triangle.fill")
                .font(Theme.dynLabel)
                .foregroundStyle(Theme.warn)
                .fixedSize(horizontal: false, vertical: true)
            Divider()
            HStack(spacing: Theme.spacing) {
                Text(store.t("soil_moisture"))
                    .font(Theme.label)
                    .foregroundStyle(Theme.inkStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 0)
                ForEach(Simulation.soilMoisture, id: \.depthCm) { reading in
                    VStack(spacing: 2) {
                        Text(verbatim: "\(reading.percent)%")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.ink)
                        Text(verbatim: "\(reading.depthCm) cm")
                            .font(Theme.small)
                            .foregroundStyle(Theme.inkStrong)
                    }
                    .lineLimit(1)
                }
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Pieces

struct ProgressRing: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let ringAnimation: Animation? = Theme.motion(.easeInOut(duration: 0.6), reduce: reduceMotion)
        ZStack {
            Circle()
                .stroke(Theme.ringTrack, lineWidth: lineWidth)
            if progress > 0 {
                Circle()
                    .trim(from: 0, to: min(1, progress))
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(lineWidth / 2)
        .animation(ringAnimation, value: progress)
    }
}

struct StatCircle: View {
    let symbol: String
    let value: String
    let caption: String
    let fill: Color
    let foreground: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(fill)
                VStack(spacing: 2) {
                    Image(systemName: symbol)
                        .font(Theme.headline)
                    Text(value)
                        .font(Theme.sectionTitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .contentTransition(.numericText())
                }
                .foregroundStyle(foreground)
                .padding(14)
            }
            .frame(width: 100, height: 100)
            Text(caption)
                .font(Theme.small)
                .foregroundStyle(Theme.inkStrong)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value + ", " + caption)
    }
}
