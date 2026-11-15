import SwiftUI

struct UnitCard: View {
    @Environment(AppStore.self) private var store
    let unit: Unit

    var body: some View {
        let now: Date = store.now
        let day: Double = Simulation.day(since: unit.batchStart, at: now)
        let moisture: Double = Simulation.moisture(of: unit, at: now)
        let vent: VentState = unit.ventDisplay(at: now)

        HStack(spacing: Theme.spacing) {
            MoistureRing(moisture: moisture, size: 118, animateOnAppear: true)

            VStack(alignment: .leading, spacing: Theme.space2) {
                Text(title)
                    .font(Theme.sectionTitle)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                progressLabel(day: day)
                VentIndicator(state: vent)
                GradeBadge(grade: unit.grade)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(Theme.headline)
                .foregroundStyle(Theme.inkStrong)
                .accessibilityHidden(true)
        }
        .card()
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        // One clear sentence for screen-reader users:
        // "Unit A, Chilli, Drying, Day 12 of 14, Moisture 11.8%, Vents open, Grade A".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken(day: day, moisture: moisture, vent: vent))
        .accessibilityHint(store.t("home_open_unit"))
        .accessibilityAddTraits(.isButton)
    }

    private var title: String {
        store.t("unit", ["id": unit.id]) + " · " + store.t(unit.crop)
    }

    private var modeText: String {
        store.t(unit.mode == .drying ? "mode_drying" : "mode_storing")
    }

    private func spoken(day: Double, moisture: Double, vent: VentState) -> String {
        let parts: [String] = [
            store.t("unit", ["id": unit.id]),
            store.t(unit.crop),
            modeText,
            progressText(day: day),
            store.t("moisture") + " " + Fmt.percent1(moisture),
            store.t(ventKey(vent)),
            store.t("grade", ["g": unit.grade])
        ]
        return parts.joined(separator: ", ")
    }

    /// "Day 12 of 14", or a green tick + "Dry · ready" so the word and the colour agree.
    @ViewBuilder
    private func progressLabel(day: Double) -> some View {
        let text: String = progressText(day: day)
        if isReady(day: day) {
            Label(text, systemImage: "checkmark.seal.fill")
                .font(Theme.headline)
                .foregroundStyle(Theme.good)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        } else {
            Text(text)
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
        }
    }

    private func isReady(day: Double) -> Bool {
        let p: CropProfile = Simulation.profile(for: unit.crop)
        return unit.mode == .drying && p.isDry(day)
    }

    private func ventKey(_ state: VentState) -> String {
        switch state {
        case .open: return "vent_open"
        case .closing: return "vent_closing"
        case .closed: return "vent_closed"
        }
    }

    private func progressText(day: Double) -> String {
        let p = Simulation.profile(for: unit.crop)
        switch unit.mode {
        case .drying:
            if p.isDry(day) { return store.t("ready") }
            return store.t("day_of", ["d": "\(p.dayNumber(day))", "t": "\(Int(p.unitDays))"])
        case .storing:
            return store.t("in_storage_day", ["d": "\(p.storageDay(day))"])
        }
    }
}
