import SwiftUI
import UIKit

// MARK: - Insights: what Mamori concludes from the readings, in plain sentences

struct UnitInsight: Identifiable {
    let id: Int
    let symbol: String
    let text: String
    let color: Color
}

struct UnitInsightsCard: View {
    @Environment(AppStore.self) private var store
    let unit: Unit
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(store.t("insights"), systemImage: "sparkles")
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            ForEach(insights) { item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: item.symbol)
                        .foregroundStyle(item.color)
                        .frame(width: 26)
                        .accessibilityHidden(true)
                    Text(item.text)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(Theme.headline)
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    /// Up to four facts, most urgent first. Every number comes from Simulation.
    private var insights: [UnitInsight] {
        var list: [UnitInsight] = []
        let p: CropProfile = Simulation.profile(for: unit.crop)
        let day: Double = Simulation.day(since: unit.batchStart, at: now)
        let humidity: Int = store.insideHumidity(unit)

        func add(_ symbol: String, _ text: String, _ color: Color) {
            list.append(UnitInsight(id: list.count, symbol: symbol, text: text, color: color))
        }

        if let mins = store.rainMinutesLeftNow, unit.mode == .drying {
            add("cloud.rain.fill", store.t("ins_rain", ["n": "\(mins)"]), Theme.rain)
        }

        switch unit.mode {
        case .drying:
            if p.isDry(day) {
                add("checkmark.seal.fill", store.t("ins_ready"), Theme.good)
            } else {
                add("timer", store.t("ins_ahead", ["d": "\(p.daysLeft(day))",
                                                   "f": "\(Int(p.groundDays - p.unitDays))"]), Theme.good)
                let trays: [TrayReading] = Simulation.trays(for: unit, at: now, jitter: 0)
                if let top = trays.first, let bottom = trays.last, bottom.moisture - top.moisture >= 0.3 {
                    add("arrow.up.arrow.down.circle.fill",
                        store.t("ins_tray", ["p": String(format: "%.1f", bottom.moisture - top.moisture)]), Theme.warn)
                }
            }
        case .storing:
            add("shippingbox.fill", store.t("ins_store", ["d": "\(p.storageDay(day))", "h": "\(humidity)"]), Theme.good)
        }

        let mouldOK: Bool = Theme.insideHumidityColor(humidity, drying: unit.mode == .drying) == Theme.good
        add(mouldOK ? "checkmark.shield.fill" : "exclamationmark.shield.fill",
            store.t(mouldOK ? "ins_mould_low" : "ins_mould_watch", ["h": "\(humidity)"]),
            mouldOK ? Theme.good : Theme.warn)

        if unit.crop == "Chilli" {
            if store.state.advice == .sell {
                add("indianrupeesign.circle.fill", store.t("ins_sell_now"), Theme.good)
            } else {
                add("chart.line.uptrend.xyaxis", store.t("ins_hold", ["p": "\(store.state.priceChangePercent)"]), Theme.ink)
            }
        }
        return Array(list.prefix(4))
    }
}

// MARK: - Cut-away: the unit seen from the side, tray by tray

/// Four trays stacked inside the unit, coloured from wet (blue) to dry (green).
/// Lower trays sit in cooler, damper air, so they read wetter.
/// Warm air rises through them while the vents are open; tap a tray for its readings.
struct UnitCrossSectionCard: View {
    @Environment(AppStore.self) private var store
    let unit: Unit
    let now: Date
    @State private var selected: Int? = nil

    var body: some View {
        let trays: [TrayReading] = Simulation.trays(for: unit, at: now, jitter: store.humidityJitter)
        let vent: VentState = unit.ventDisplay(at: now)
        let ventsOpen: Bool = vent == .open
        let raining: Bool = store.state.rainInMinutes != nil
        let wettest: Double = trays.map { $0.moisture }.max() ?? 0
        let driest: Double = trays.map { $0.moisture }.min() ?? 0
        let uneven: Bool = unit.mode == .drying && (wettest - driest) >= 0.3

        VStack(alignment: .leading, spacing: 12) {
            Text(store.t("unit_inside"))
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)

            VStack(spacing: 0) {
                roof(open: ventsOpen, closing: vent == .closing, raining: raining)
                    .frame(height: 58)
                HStack(spacing: 8) {
                    VStack(spacing: 6) {
                        ForEach(trays) { tray in
                            trayRow(tray, count: trays.count,
                                    flag: uneven && tray.moisture == wettest)
                        }
                    }
                    AirflowColumn(active: ventsOpen && unit.mode == .drying)
                        .frame(width: 30)
                        .accessibilityHidden(true)
                }
                .padding(10)
                .background(Theme.unitShell)
                .overlay(Rectangle().stroke(Theme.unitFrame, lineWidth: 3))
                Rectangle()
                    .fill(Theme.ground)
                    .frame(height: 8)
            }

            Label(store.t(ventsOpen ? "airflow_on" : "airflow_off"),
                  systemImage: ventsOpen ? "wind" : "lock.fill")
                .font(Theme.label)
                .foregroundStyle(ventsOpen ? Theme.ink : Theme.rain)
                .fixedSize(horizontal: false, vertical: true)

            if let id = selected, let tray = trays.first(where: { $0.id == id }) {
                trayDetail(tray, count: trays.count)
            } else {
                Text(store.t("tap_tray"))
                    .font(Theme.label)
                    .foregroundStyle(Theme.inkMuted)
            }

            if uneven {
                Label(store.t("tray_tip"), systemImage: "arrow.up.arrow.down.circle.fill")
                    .font(Theme.label)
                    .foregroundStyle(Theme.warn)
                    .fixedSize(horizontal: false, vertical: true)
            }

            legend
        }
        .card()
    }

    // Gable roof with two vent flaps that swing shut when rain is coming.
    private func roof(open: Bool, closing: Bool, raining: Bool) -> some View {
        ZStack(alignment: .bottom) {
            RoofShape()
                .fill(Theme.unitShell)
            RoofShape()
                .stroke(Theme.unitFrame, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
            HStack {
                ventFlap(open: open, closing: closing, mirrored: false)
                Spacer()
                Image(systemName: raining ? "cloud.rain.fill" : "sun.max.fill")
                    .font(Theme.sectionTitle)
                    .foregroundStyle(raining ? Theme.rain : Theme.sun)
                    .offset(y: -18)
                Spacer()
                ventFlap(open: open, closing: closing, mirrored: true)
            }
            .padding(.horizontal, 44)
            .padding(.bottom, 14)
        }
        .animation(.easeInOut(duration: 0.8), value: open)
    }

    private func ventFlap(open: Bool, closing: Bool, mirrored: Bool) -> some View {
        let angle: Double = open ? 35 : 0
        return Capsule()
            .fill(open ? Theme.accent : (closing ? Theme.warn : Theme.unitFrame))
            .frame(width: 38, height: 9)
            .rotationEffect(.degrees(mirrored ? angle : -angle), anchor: mirrored ? .trailing : .leading)
    }

    private func trayRow(_ tray: TrayReading, count: Int, flag: Bool) -> some View {
        let isSelected: Bool = selected == tray.id
        var name: String = store.t("tray_n", ["n": "\(tray.id)"])
        if tray.id == 1 { name += " · " + store.t("top") }
        if tray.id == count { name += " · " + store.t("bottom") }
        let value: String = Fmt.percent1(tray.moisture)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selected = isSelected ? nil : tray.id }
        } label: {
            HStack(spacing: 8) {
                Text(name)
                    .font(Theme.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if flag {
                    Image(systemName: "drop.fill")
                        .font(Theme.label)
                }
                Spacer(minLength: 4)
                Text(value)
                    .font(Theme.headline)
                    .contentTransition(.numericText())
            }
            .foregroundStyle(Theme.onDark)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(Theme.wetnessRamp(tray.moisture), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Theme.accent : Theme.clear, lineWidth: 4)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([name, store.t("moisture") + " " + value,
                             "\(tray.tempC) °C", store.t("humidity_inside") + " \(tray.humidity)%"].joined(separator: ", "))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func trayDetail(_ tray: TrayReading, count: Int) -> some View {
        let drying: Bool = unit.mode == .drying
        var name: String = store.t("tray_n", ["n": "\(tray.id)"])
        if tray.id == 1 { name += " · " + store.t("top") }
        if tray.id == count { name += " · " + store.t("bottom") }

        return VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
            HStack(spacing: 16) {
                Label(Fmt.percent1(tray.moisture), systemImage: "drop.fill")
                    .foregroundStyle(Theme.wetnessRamp(tray.moisture))
                Label("\(tray.tempC) °C", systemImage: "thermometer.medium")
                    .foregroundStyle(Theme.chamberTempColor(tray.tempC))
                Label("\(tray.humidity)%", systemImage: "humidity.fill")
                    .foregroundStyle(Theme.insideHumidityColor(tray.humidity, drying: drying))
                Spacer(minLength: 0)
            }
            .font(Theme.headline)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .contentTransition(.numericText())
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
        .transition(.opacity)
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 14) {
                legendItem(Theme.wetnessRamp(30), store.t("legend_wet"))
                legendItem(Theme.wetnessRamp(13.5), store.t("legend_drying"))
                legendItem(Theme.wetnessRamp(11), store.t("legend_dry"))
                Spacer(minLength: 0)
            }
            Text(verbatim: "4.8 × 2.4 × 2.0 m")
                .font(Theme.caption)
                .foregroundStyle(Theme.inkMuted)
        }
        .accessibilityElement(children: .combine)
    }

    private func legendItem(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 12, height: 12)
            Text(text)
                .font(Theme.caption)
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Gable roof outline.
struct RoofShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Chevrons drifting upward: warm air rising through the trays. Still when the vents are shut.
struct AirflowColumn: View {
    let active: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !active)) { context in
            Canvas { ctx, size in
                let spacing: Double = 34
                let t: Double = context.date.timeIntervalSinceReferenceDate
                let shift: Double = active ? (t * 28).truncatingRemainder(dividingBy: spacing) : 0
                let cx: Double = size.width / 2
                var path = Path()
                var y: Double = size.height + spacing - shift
                while y > -spacing {
                    path.move(to: CGPoint(x: cx - 9, y: y + 6))
                    path.addLine(to: CGPoint(x: cx, y: y - 3))
                    path.addLine(to: CGPoint(x: cx + 9, y: y + 6))
                    y -= spacing
                }
                ctx.stroke(path,
                           with: .color(active ? Theme.airflow : Theme.airflowIdle),
                           style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

// MARK: - Camera: live view with the grading boxes drawn on top

struct CameraCard: View {
    @Environment(AppStore.self) private var store
    let unit: Unit
    let now: Date
    @State private var showGrading = true

    /// Where the grading boxes sit on the picture (fractions of width and height),
    /// with the confidence shown on each. PLACEHOLDER confidences.
    private static let boxes: [(rect: CGRect, confidence: Int)] = [
        (CGRect(x: 0.07, y: 0.16, width: 0.24, height: 0.34), 94),
        (CGRect(x: 0.40, y: 0.44, width: 0.22, height: 0.36), 91),
        (CGRect(x: 0.69, y: 0.14, width: 0.24, height: 0.38), 96),
        (CGRect(x: 0.13, y: 0.60, width: 0.20, height: 0.28), 89)
    ]

    private var assetName: String { unit.crop == "Turmeric" ? "turmeric_batch" : "chilli_batch" }

    private var minutesAgo: Int {
        // Camera re-checks every 15 minutes, so this cycles 1...14.
        max(1, Int(now.timeIntervalSince(unit.gradedAt) / 60) % 15)
    }

    var body: some View {
        let blink: Bool = Int(now.timeIntervalSince1970) % 2 == 0
        let summary: String = [store.t("grade", ["g": unit.grade]),
                               store.t("colour") + " \(unit.colourScore)/100",
                               store.t("mould_risk") + ": " + store.t(unit.mouldRisk)].joined(separator: " · ")

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(store.t("camera"))
                    .font(Theme.sectionTitle)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 8)
                Button {
                    withAnimation { showGrading.toggle() }
                } label: {
                    Text(store.t(showGrading ? "hide_grading" : "show_grading"))
                        .font(Theme.caption)
                        .foregroundStyle(Theme.onDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.ink, in: Capsule())
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Color.clear
                .frame(height: 210)
                .overlay { photo }
                .overlay {
                    if showGrading {
                        gradingBoxes
                        ScanLine()
                    }
                }
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.danger)
                            .frame(width: 10, height: 10)
                            .opacity(blink ? 1 : 0.25)
                        Text(store.t("live"))
                    }
                    .font(Theme.label)
                    .foregroundStyle(Theme.onDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.cameraOverlay, in: Capsule())
                    .padding(10)
                }
                .overlay(alignment: .topTrailing) {
                    Text(now.formatted(date: .omitted, time: .standard))
                        .font(Theme.label)
                        .monospacedDigit()
                        .foregroundStyle(Theme.onDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.cameraOverlay, in: Capsule())
                        .padding(10)
                }
                .overlay(alignment: .bottomLeading) {
                    Text(store.t("unit", ["id": unit.id]) + " · " + store.t("tray_n", ["n": "1"]))
                        .font(Theme.label)
                        .foregroundStyle(Theme.onDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.cameraOverlay, in: Capsule())
                        .padding(10)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.tileRadius))

            Text(summary)
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(store.t("checked_ago", ["m": "\(minutesAgo)"]))
                .font(Theme.caption)
                .foregroundStyle(Theme.inkMuted)
        }
        .card()
    }

    private var gradingBoxes: some View {
        GeometryReader { geo in
            ForEach(Self.boxes.indices, id: \.self) { i in
                let box: CGRect = Self.boxes[i].rect
                let label: String = unit.grade + " · \(Self.boxes[i].confidence)%"
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Theme.accent, lineWidth: 3)
                    .overlay(alignment: .topLeading) {
                        Text(label)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.onAccent)
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accent)
                    }
                    .frame(width: geo.size.width * box.width, height: geo.size.height * box.height)
                    .position(x: geo.size.width * box.midX, y: geo.size.height * box.midY)
            }
        }
        .transition(.opacity)
    }

    @ViewBuilder
    private var photo: some View {
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(colors: [Theme.cameraPlaceholderTop, Theme.cameraPlaceholderBottom],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

/// A lime band sweeping down the picture: the camera "scanning" the batch.
struct ScanLine: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            GeometryReader { geo in
                let progress: Double = (context.date.timeIntervalSinceReferenceDate / 3)
                    .truncatingRemainder(dividingBy: 1)
                let band: CGFloat = 46
                LinearGradient(colors: [Theme.clear, Theme.scanLine, Theme.clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: band)
                    .offset(y: CGFloat(progress) * (geo.size.height + band) - band)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Shared helpers for the unit cards

enum UnitText {
    static func date(_ d: Date, lang: String) -> String {
        d.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(L10n.locale(lang)))
    }
}

/// One line of a reading card: icon, label (wraps), value.
struct ReadingRow: View {
    let symbol: String
    let label: String
    let value: String
    var valueColor: Color = Theme.ink

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: symbol)
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(label)
                .font(Theme.label)
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Text(value)
                .font(Theme.sectionTitle)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Power: solar panel, battery, fan

struct UnitPowerCard: View {
    @Environment(AppStore.self) private var store
    let unit: Unit
    let now: Date

    var body: some View {
        let vent: VentState = unit.ventDisplay(at: now)
        let raining: Bool = store.state.rainInMinutes != nil
        let watts: Int = UnitSim.panelWatts(raining: raining)
        let fan: Int = UnitSim.fanSpeedPercent(unit: unit, vent: vent)
        let charging: Bool = UnitSim.isCharging(unit: unit, vent: vent, raining: raining)
        let solarLabel: String = store.t("u_solar_now") + " · " + store.t("u_of_rated", ["w": "\(UnitSim.panelRatedWatts)"])
        let batteryLabel: String = charging ? store.t("battery") + " · " + store.t("u_charging") : store.t("battery")
        let fanValue: String = fan > 0 ? "\(fan)%" : store.t("off")
        let fanDetail: String = fanDetailText(fan: fan)
        let solarColor: Color = raining ? Theme.warn : Theme.good
        let solarSymbol: String = raining ? "cloud.sun.fill" : "sun.max.fill"
        let spoken: String = [store.t("u_power"),
                              solarLabel + ": \(watts) W",
                              batteryLabel + ": \(Simulation.batteryPercent)%",
                              store.t("fan") + ": " + fanDetail].joined(separator: ". ")

        VStack(alignment: .leading, spacing: 6) {
            Label(store.t("u_power"), systemImage: "bolt.fill")
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
            ReadingRow(symbol: solarSymbol, label: solarLabel, value: "\(watts) W", valueColor: solarColor)
            Divider()
            ReadingRow(symbol: "battery.100", label: batteryLabel, value: "\(Simulation.batteryPercent)%")
            Divider()
            ReadingRow(symbol: "wind", label: store.t("fan"), value: fanValue)
            Text(fanDetail)
                .font(Theme.label)
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private func fanDetailText(fan: Int) -> String {
        if fan > 0 { return store.t("u_fan_speed", ["p": "\(fan)"]) }
        if unit.mode == .storing { return store.t("u_fan_off_store") }
        return store.t("u_fan_off_rain")
    }
}

// MARK: - Timeline of this batch

struct TimelineStep: Identifiable {
    let id: Int
    let title: String
    let date: String
    let done: Bool
    let current: Bool
}

struct BatchTimelineCard: View {
    @Environment(AppStore.self) private var store
    let unit: Unit
    let now: Date

    var body: some View {
        let list: [TimelineStep] = steps
        VStack(alignment: .leading, spacing: 0) {
            Label(store.t("u_timeline"), systemImage: "calendar")
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
                .padding(.bottom, 8)
            ForEach(list) { step in
                stepRow(step, last: step.id == list.count - 1)
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    private var steps: [TimelineStep] {
        let p: CropProfile = Simulation.profile(for: unit.crop)
        let day: Double = Simulation.day(since: unit.batchStart, at: now)
        let dryDate: Date = unit.batchStart.addingTimeInterval(p.unitDays * Simulation.secondsPerDay)
        let dryTitle: String = store.t("u_tl_dry", ["m": "\(Int(Simulation.targetMoisture))"])
        let l: String = store.lang
        var out: [TimelineStep] = []
        out.append(TimelineStep(id: 0, title: store.t("u_tl_loaded") + " · " + Fmt.kg(unit.weightKg),
                                date: UnitText.date(unit.batchStart, lang: l), done: true, current: false))
        switch unit.mode {
        case .drying:
            let dry: Bool = p.isDry(day)
            if !dry {
                out.append(TimelineStep(id: 1, title: store.t("u_tl_today", ["d": "\(p.dayNumber(day))"]),
                                        date: UnitText.date(now, lang: l), done: false, current: true))
            }
            out.append(TimelineStep(id: out.count, title: dryTitle,
                                    date: UnitText.date(dryDate, lang: l), done: dry, current: dry))
            out.append(TimelineStep(id: out.count, title: store.t("u_tl_store"),
                                    date: "", done: false, current: false))
        case .storing:
            let stored: Int = p.storageDay(day)
            let left: Int = UnitSim.safeDaysLeft(storedDays: stored, humidity: store.insideHumidity(unit))
            let safeUntil: Date = now.addingTimeInterval(Double(left) * Simulation.secondsPerDay)
            out.append(TimelineStep(id: 1, title: dryTitle,
                                    date: UnitText.date(dryDate, lang: l), done: true, current: false))
            out.append(TimelineStep(id: 2, title: store.t("in_storage_day", ["d": "\(stored)"]),
                                    date: UnitText.date(now, lang: l), done: false, current: true))
            out.append(TimelineStep(id: 3, title: store.t("u_tl_safe"),
                                    date: UnitText.date(safeUntil, lang: l), done: false, current: false))
        }
        return out
    }

    private func stepRow(_ step: TimelineStep, last: Bool) -> some View {
        let symbol: String
        let color: Color
        let status: String
        if step.done && !step.current {
            symbol = "checkmark.circle.fill"
            color = Theme.good
            status = store.t("u_done")
        } else if step.current {
            symbol = "largecircle.fill.circle"
            color = Theme.ink
            status = store.t("now")
        } else {
            symbol = "circle"
            color = Theme.inkMuted
            status = store.t("u_next")
        }
        let titleFont: Font = step.current ? Theme.headline : Theme.label
        return HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: symbol)
                    .font(Theme.headline)
                    .foregroundStyle(color)
                if !last {
                    Rectangle()
                        .fill(Theme.ringTrack)
                        .frame(width: 3, height: 26)
                }
            }
            .frame(width: 28)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(titleFont)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !step.date.isEmpty {
                    Text(step.date)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.inkMuted)
                }
            }
            Spacer(minLength: 0)
            Text(status)
                .font(Theme.caption)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

// MARK: - Storage detail (storing units, e.g. Unit B)

struct StorageDetailCard: View {
    @Environment(AppStore.self) private var store
    let unit: Unit
    let now: Date

    var body: some View {
        let p: CropProfile = Simulation.profile(for: unit.crop)
        let day: Double = Simulation.day(since: unit.batchStart, at: now)
        let stored: Int = p.storageDay(day)
        let humidity: Int = store.insideHumidity(unit)
        let left: Int = UnitSim.safeDaysLeft(storedDays: stored, humidity: humidity)
        let bags: Int = unit.bags ?? UnitSim.bagsFor(kg: unit.weightKg)
        let bagsText: String = store.t("bags_of", ["n": "\(bags)", "c": "\(Simulation.bagsPerUnit)"])
        let gradeText: String = store.t("grade", ["g": unit.grade]) + " · " + store.t("colour") + " \(unit.colourScore)/100"
        let humidColor: Color = Theme.insideHumidityColor(humidity, drying: false)
        let humidLine: String = store.t("u_humidity_vs_mould", ["h": "\(humidity)", "t": "\(UnitSim.mouldHumidityLine)"])
        let spoken: String = [store.t("u_storage"),
                              bagsText + ", " + Fmt.kg(unit.weightKg),
                              store.t("u_days_stored") + ": \(stored)",
                              humidLine,
                              store.t("u_safe_left") + ": \(left)",
                              gradeText].joined(separator: ". ")

        VStack(alignment: .leading, spacing: 6) {
            Label(store.t("u_storage"), systemImage: "shippingbox.fill")
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
            VStack(alignment: .leading, spacing: 6) {
                ReadingRow(symbol: "bag.fill", label: store.t("u_bags_title"), value: "\(bags)")
                Text(bagsText + " · " + Fmt.kg(unit.weightKg))
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                Divider()
                ReadingRow(symbol: "calendar", label: store.t("u_days_stored"), value: "\(stored)")
                Divider()
            }
            VStack(alignment: .leading, spacing: 6) {
                ReadingRow(symbol: "humidity.fill", label: store.t("humidity_inside"),
                           value: "\(humidity)%", valueColor: humidColor)
                HumidityGauge(value: humidity, line: UnitSim.mouldHumidityLine, color: humidColor,
                              lineLabel: store.t("u_mould_line"))
                Text(humidLine)
                    .font(Theme.label)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Divider()
            }
            VStack(alignment: .leading, spacing: 6) {
                ReadingRow(symbol: "checkmark.shield.fill", label: store.t("u_safe_left"),
                           value: "\(left)", valueColor: Theme.good)
                Text(store.t("u_safe_note", ["d": "\(UnitSim.safeStorageDays)"]))
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                Divider()
                ReadingRow(symbol: "seal.fill", label: gradeText, value: unit.grade, valueColor: Theme.good)
            }
        }
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }
}

/// 0–100% bar with a marked line (e.g. the mould threshold).
struct HumidityGauge: View {
    let value: Int
    let line: Int
    let color: Color
    let lineLabel: String

    var body: some View {
        let fraction: Double = min(1, max(0, Double(value) / 100))
        let lineFraction: Double = min(1, max(0, Double(line) / 100))
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                let w: CGFloat = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.ringTrack)
                    Capsule()
                        .fill(color)
                        .frame(width: w * CGFloat(fraction))
                    Rectangle()
                        .fill(Theme.danger)
                        .frame(width: 4)
                        .offset(x: w * CGFloat(lineFraction) - 2)
                }
            }
            .frame(height: 16)
            HStack(spacing: 4) {
                Text(verbatim: "0%")
                Spacer(minLength: 0)
                Text(lineLabel + " \(line)%")
                    .foregroundStyle(Theme.danger)
                Text(verbatim: "· 100%")
            }
            .font(Theme.caption)
            .foregroundStyle(Theme.inkMuted)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        .accessibilityHidden(true)
    }
}
