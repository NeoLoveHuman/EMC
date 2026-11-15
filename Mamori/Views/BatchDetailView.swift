import SwiftUI
import Charts

struct BatchDetailView: View {
    @Environment(AppStore.self) private var store
    let unitID: String

    var body: some View {
        Group {
            if let unit = store.unit(unitID) {
                content(unit)
            } else {
                Text(verbatim: "—")
            }
        }
        // Tells the voice assistant which unit is open.
        .onAppear { store.focusedUnitID = unitID }
        .onDisappear { if store.focusedUnitID == unitID { store.focusedUnitID = nil } }
    }

    private func content(_ unit: Unit) -> some View {
        let now: Date = store.now
        let day: Double = Simulation.day(since: unit.batchStart, at: now)
        let moisture: Double = Simulation.moisture(of: unit, at: now)
        let profile: CropProfile = Simulation.profile(for: unit.crop)
        let chartDay: Double = unit.mode == .drying ? day : profile.unitDays

        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacing) {
                ringSection(unit: unit, day: day, moisture: moisture)
                UnitInsightsCard(unit: unit, now: now)
                if unit.mode == .storing {
                    StorageDetailCard(unit: unit, now: now)
                }
                DryingChart(profile: profile, currentDay: chartDay)
                BatchTimelineCard(unit: unit, now: now)
                UnitCrossSectionCard(unit: unit, now: now)
                tiles(unit: unit)
                UnitPowerCard(unit: unit, now: now)
                ventSection(unit: unit, now: now)
                CameraCard(unit: unit, now: now)
            }
            .padding(Theme.padding)
            // Room for the custom tab bar and the floating mic.
            .padding(.bottom, Theme.scrollBottomInset)
        }
        .background(Theme.background)
        .navigationTitle(store.t("unit", ["id": unit.id]) + " · " + store.t(unit.crop))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Ring

    private func ringSection(unit: Unit, day: Double, moisture: Double) -> some View {
        VStack(spacing: 10) {
            MoistureRing(moisture: moisture,
                         size: 230,
                         lineWidth: Theme.detailRingLineWidth,
                         numberFont: Theme.detailRingNumber,
                         caption: store.t("moisture"))
            Text(store.t("target", ["n": "11"]))
                .font(Theme.label)
                .foregroundStyle(Theme.inkMuted)
            Text(statusLine(unit: unit, day: day))
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private func statusLine(unit: Unit, day: Double) -> String {
        let p = Simulation.profile(for: unit.crop)
        switch unit.mode {
        case .drying:
            if p.isDry(day) { return store.t("ready") }
            return store.t("day_of", ["d": "\(p.dayNumber(day))", "t": "\(Int(p.unitDays))"])
                + " · " + store.t("days_left", ["d": "\(p.daysLeft(day))"])
        case .storing:
            var line = store.t("in_storage_day", ["d": "\(p.storageDay(day))"])
            if let bags = unit.bags {
                line += " · " + store.t("bags_of", ["n": "\(bags)", "c": "\(Simulation.bagsPerUnit)"])
            }
            return line
        }
    }

    // MARK: Vents

    private func ventSection(unit: Unit, now: Date) -> some View {
        let display: VentState = unit.ventDisplay(at: now)
        // While the flaps are still closing the button is locked, so a second tap
        // cannot reopen them half way.
        let closing: Bool = display == .closing
        let raining: Bool = store.state.rainInMinutes != nil
        let showAuto: Bool = raining && unit.vent == .closed && unit.mode == .drying
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(store.t("vents"))
                    .font(Theme.sectionTitle)
                    .foregroundStyle(Theme.ink)
                Spacer()
                VentIndicator(state: display, large: true)
            }
            if showAuto {
                Label(store.t("closed_auto"), systemImage: "cloud.rain.fill")
                    .font(Theme.label)
                    .foregroundStyle(Theme.rain)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ventButton(unit: unit, closing: closing)
        }
        .card()
    }

    private func ventButton(unit: Unit, closing: Bool) -> some View {
        let key: String
        if closing {
            key = "vent_closing"
        } else if unit.vent == .open {
            key = "close_vents"
        } else {
            key = "open_vents"
        }
        let fill: Color = closing ? Theme.inkMuted : Theme.ink
        return Button {
            store.setVents(open: unit.vent != .open, unitID: unit.id)
        } label: {
            Text(store.t(key))
                .font(Theme.headline)
                .foregroundStyle(Theme.onDark)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.vertical, 8)
                .background(fill, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
        }
        .buttonStyle(.plain)
        .disabled(closing)
    }

    // MARK: Tiles

    /// Inside readings, colour-coded (green fine, amber watch, red bad), compared with outside.
    private func tiles(unit: Unit) -> some View {
        let drying: Bool = unit.mode == .drying
        let temp: Int = store.insideTemp(unit)
        let humidity: Int = store.insideHumidity(unit)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                StatTile(title: store.t("temp_inside"), value: "\(temp) °C", symbol: "thermometer.medium",
                         valueColor: Theme.chamberTempColor(temp))
                StatTile(title: store.t("humidity_inside"), value: "\(humidity)%", symbol: "humidity.fill",
                         valueColor: Theme.insideHumidityColor(humidity, drying: drying))
                StatTile(title: store.t("weight"), value: Fmt.kg(unit.weightKg), symbol: "scalemass.fill")
            }
            Text(store.t("outside_now", ["t": "\(Simulation.outsideTempC)", "h": "\(Simulation.outsideHumidity)"]))
                .font(Theme.label)
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Drying chart: the single most important visual (14 vs 22 days)

struct DryingChart: View {
    @Environment(AppStore.self) private var store
    let profile: CropProfile
    let currentDay: Double

    private var fasterDays: Int { Int(profile.groundDays - profile.unitDays) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.t("drying_curve"))
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
            Text(store.t("fourteen_vs", ["a": "\(Int(profile.unitDays))", "b": "\(Int(profile.groundDays))"]))
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            fasterPill
            chart
                .frame(height: 260)
            legend
        }
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenSummary)
    }

    /// "8 days faster than open ground": text and icon, not colour alone.
    private var fasterPill: some View {
        Label(store.t("u_faster_ground", ["d": "\(fasterDays)"]), systemImage: "bolt.fill")
            .font(Theme.label)
            .foregroundStyle(Theme.onDark)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.good, in: Capsule())
    }

    private var spokenSummary: String {
        let d: Double = min(currentDay, profile.unitDays)
        let parts: [String] = [
            store.t("drying_curve"),
            store.t("series_unit") + " " + store.t("days_n", ["d": "\(Int(profile.unitDays))"]),
            store.t("series_ground") + " " + store.t("days_n", ["d": "\(Int(profile.groundDays))"]),
            store.t("u_faster_ground", ["d": "\(fasterDays)"]),
            store.t("today") + " " + Fmt.percent1(profile.moistureUnit(d))
        ]
        return parts.joined(separator: ". ")
    }

    private var xMarks: [Double] {
        [0.0, (profile.unitDays / 2).rounded(), profile.unitDays, profile.groundDays]
    }

    private var chart: some View {
        Chart {
            groundCurve
            unitCurve
            guides
            today
        }
        .chartXScale(domain: 0.0...profile.groundDays)
        .chartYScale(domain: 0.0...75.0)
        .chartXAxis {
            AxisMarks(values: xMarks) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text(verbatim: "\(Int(d))").font(Theme.label)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0.0, 11.0, 25.0, 50.0, 75.0]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let m = value.as(Double.self) {
                        Text(verbatim: "\(Int(m))%").font(Theme.label)
                    }
                }
            }
        }
    }

    @ChartContentBuilder
    private var groundCurve: some ChartContent {
        let name = store.t("series_ground")
        ForEach(profile.curveDaysGround, id: \.self) { d in
            LineMark(x: .value("Day", d),
                     y: .value("Moisture", profile.moistureGround(d)),
                     series: .value("Series", name))
                .foregroundStyle(Theme.chartGround)
                .lineStyle(StrokeStyle(lineWidth: 3, dash: [7, 5]))
        }
    }

    @ChartContentBuilder
    private var unitCurve: some ChartContent {
        let name = store.t("series_unit")
        ForEach(profile.curveDaysUnit, id: \.self) { d in
            LineMark(x: .value("Day", d),
                     y: .value("Moisture", profile.moistureUnit(d)),
                     series: .value("Series", name))
                .foregroundStyle(Theme.chartUnit)
                .lineStyle(StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }

    @ChartContentBuilder
    private var guides: some ChartContent {
        RuleMark(y: .value("Target", Simulation.targetMoisture))
            .foregroundStyle(Theme.chartGuide)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

        PointMark(x: .value("Day", profile.unitDays),
                  y: .value("Moisture", profile.moistureUnit(profile.unitDays)))
            .foregroundStyle(Theme.chartUnit)
            .symbolSize(90)
            .annotation(position: .top, spacing: 6) {
                Text(verbatim: "\(Int(profile.unitDays))").font(Theme.sectionTitle).foregroundStyle(Theme.ink)
            }

        PointMark(x: .value("Day", profile.groundDays),
                  y: .value("Moisture", profile.moistureGround(profile.groundDays)))
            .foregroundStyle(Theme.chartGround)
            .symbolSize(90)
            .annotation(position: .top, spacing: 6) {
                Text(verbatim: "\(Int(profile.groundDays))").font(Theme.sectionTitle).foregroundStyle(Theme.chartGround)
            }
    }

    @ChartContentBuilder
    private var today: some ChartContent {
        let d = min(currentDay, profile.unitDays)
        PointMark(x: .value("Day", d), y: .value("Moisture", profile.moistureUnit(d)))
            .foregroundStyle(Theme.ink)
            .symbolSize(420)
        PointMark(x: .value("Day", d), y: .value("Moisture", profile.moistureUnit(d)))
            .foregroundStyle(Theme.accent)
            .symbolSize(220)
    }

    /// Two lines, so long Telugu and Hindi labels wrap instead of shrinking.
    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            legendItem(color: Theme.chartUnit, dashed: false,
                       text: store.t("series_unit") + " · " + store.t("days_n", ["d": "\(Int(profile.unitDays))"]))
            legendItem(color: Theme.chartGround, dashed: true,
                       text: store.t("series_ground") + " · " + store.t("days_n", ["d": "\(Int(profile.groundDays))"]))
        }
        .font(Theme.label)
        .foregroundStyle(Theme.ink)
    }

    private func legendItem(color: Color, dashed: Bool, text: String) -> some View {
        let dash: [CGFloat] = dashed ? [5, 3] : []
        return HStack(spacing: 8) {
            Capsule()
                .stroke(color, style: StrokeStyle(lineWidth: 4, dash: dash))
                .frame(width: 28, height: 2)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
