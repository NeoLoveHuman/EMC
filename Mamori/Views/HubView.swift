import SwiftUI

/// Hub operator's view: all 20 units of one village yard on one screen.
/// Tap a unit to see what is in it.
struct HubView: View {
    @Environment(AppStore.self) private var store
    @State private var selected: Int? = 20
    @State private var filter: Mode?? = nil      // nil = show all; .some(nil) = empty units

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        let units: [HubUnit] = Simulation.hubUnits
        let drying: Int = units.filter { $0.mode == .drying }.count
        let storing: Int = units.filter { $0.mode == .storing }.count
        let empty: Int = units.count - drying - storing
        let sumLine: String = store.t("u_counts_sum", ["d": "\(drying)", "s": "\(storing)",
                                                       "e": "\(empty)", "n": "\(units.count)"])

        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text(store.t("hub_title", ["n": "\(units.count)"]))
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            seasonCard(drying: drying)

            Label(store.t("hub_ready", ["n": "\(Simulation.hubReadyCount)"]), systemImage: "checkmark.seal.fill")
                .font(Theme.headline)
                .foregroundStyle(Theme.good)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                count(drying, store.t("mode_drying"), fill: Theme.accent, ink: Theme.onAccent, mode: .drying)
                count(storing, store.t("mode_storing"), fill: Theme.ink, ink: Theme.onDark, mode: .storing)
                count(empty, store.t("hub_empty"), fill: Theme.ringTrack, ink: Theme.ink, mode: nil)
            }
            Text(sumLine)
                .font(Theme.label)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(store.t("hub_filter_hint"))
                .font(Theme.caption)
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(units) { unit in
                    cell(unit)
                }
            }
            .card()

            detail(units.first { $0.id == selected })

            HubTasksCard()
            HubQueueCard()
        }
        // Room for the custom tab bar and the floating mic (HubView is the last thing on the Units tab).
        .padding(.bottom, Theme.scrollBottomInset)
    }

    // MARK: Season totals: fee = rate × kg dried

    private func seasonCard(drying: Int) -> some View {
        let dried: Int = Simulation.hubDriedKgThisSeason
        let formula: String = store.t("u_fee_formula", ["kg": Fmt.kg(dried),
                                                        "r": Fmt.rupees(Simulation.hubFeePer100kg),
                                                        "v": Fmt.rupees(Simulation.hubFeesThisSeason)])
        let toBill: String = store.t("u_to_bill", ["n": "\(drying)", "v": Fmt.rupees(UnitSim.hubFeesToBill)])
        let storedOnly: Int = UnitSim.hubStoredOnlyKg
        let storedOnlyText: String = store.t("u_stored_only", ["kg": Fmt.kg(storedOnly)])
        let farmers: String = store.t("hub_farmers", ["n": "\(Simulation.hubFarmers)"])
        let storedValue: String = String(format: "%.1f t", Simulation.hubStoredTonnes)
        let driedValue: String = String(format: "%.1f t", Double(dried) / 1_000)

        return VStack(alignment: .leading, spacing: 10) {
            Label(store.t("u_season"), systemImage: "chart.bar.fill")
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
            HStack(spacing: 10) {
                StatTile(title: store.t("u_dried_here"), value: driedValue, symbol: "sun.max.fill")
                StatTile(title: store.t("hub_stored", ["c": "\(Simulation.hubCapacityTonnes)"]),
                         value: storedValue, symbol: "shippingbox.fill")
            }
            StatTile(title: store.t("hub_fees"),
                     value: Fmt.rupees(Simulation.hubFeesThisSeason),
                     symbol: "indianrupeesign.circle.fill",
                     valueColor: Theme.good)
            Text(formula)
                .font(Theme.label)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(toBill)
                .font(Theme.label)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if storedOnly > 0 {
                Text(storedOnlyText)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(farmers)
                .font(Theme.caption)
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    /// Tap a count to show only those units in the yard; tap again to show all.
    private func count(_ n: Int, _ label: String, fill: Color, ink: Color, mode: Mode?) -> some View {
        let active: Bool = filter.map { $0 == mode } ?? false
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { filter = active ? nil : .some(mode) }
        } label: {
            VStack(spacing: 2) {
                Text(verbatim: "\(n)")
                    .font(Theme.bigNumber)
                Text(label)
                    .font(Theme.caption)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 10)
            .background(fill, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.tileRadius)
                    .stroke(active ? Theme.warn : Theme.clear, lineWidth: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(active ? [.isButton, .isSelected] : .isButton)
    }

    private func isReady(_ unit: HubUnit) -> Bool {
        unit.mode == .drying && unit.day >= Simulation.chilli.unitDays - 2
    }

    private func summary(_ unit: HubUnit) -> String {
        let p = Simulation.chilli
        switch unit.mode {
        case .drying?:
            let day: String = store.t("day_of", ["d": "\(p.dayNumber(unit.day))", "t": "\(Int(p.unitDays))"])
            let moisture: String = store.t("moisture") + " " + Fmt.percent1(p.moistureUnit(unit.day))
            let left: String = store.t("days_left_short", ["d": "\(p.daysLeft(unit.day))"])
            return [store.t("Chilli"), store.t("mode_drying"), day, moisture, left].joined(separator: " · ")
        case .storing?:
            let bags: String = store.t("bags_of", ["n": "\(unit.bags)", "c": "\(Simulation.bagsPerUnit)"])
            let weight: String = Fmt.kg(unit.bags * Simulation.kgPerBag)
            return [store.t("Chilli"), store.t("mode_storing"), bags, weight].joined(separator: " · ")
        case .none:
            return store.t("hub_empty")
        }
    }

    /// Second line of the detail card: who, when ready, what it earns, or how long it keeps.
    private func extra(_ unit: HubUnit) -> [String] {
        let p = Simulation.chilli
        let farmer: String = store.t("u_hub_unit_farmer", ["f": UnitSim.farmer(unit.id)])
        switch unit.mode {
        case .drying?:
            let kg: Int = UnitSim.dryingLoadKg(unit.id)
            let readyDate: Date = store.now.addingTimeInterval(Double(p.daysLeft(unit.day)) * Simulation.secondsPerDay)
            let ready: String = store.t("u_ready_on", ["date": UnitText.date(readyDate, lang: store.lang)])
            let fee: String = store.t("u_load_fee", ["kg": Fmt.kg(kg), "v": Fmt.rupees(UnitSim.fee(forKg: kg))])
            return [farmer, ready, fee]
        case .storing?:
            let days: Int = UnitSim.storageDays(unit.id)
            let humidity: Int = UnitSim.hubStorageHumidity
            let stored: String = store.t("in_storage_day", ["d": "\(days)"])
            let humid: String = store.t("u_humidity_vs_mould", ["h": "\(humidity)", "t": "\(UnitSim.mouldHumidityLine)"])
            let safe: String = store.t("u_safe_days", ["d": "\(UnitSim.safeDaysLeft(storedDays: days, humidity: humidity))"])
            return [farmer, stored, humid, safe]
        case .none:
            guard let next = UnitSim.hubAssignments.first(where: { $0.unitID == unit.id }) else { return [] }
            return [store.t("u_task_load", ["id": "\(unit.id)", "f": next.booking.farmer])]
        }
    }

    @ViewBuilder
    private func detail(_ unit: HubUnit?) -> some View {
        if let unit {
            let lines: [String] = extra(unit)
            VStack(alignment: .leading, spacing: 6) {
                Text(store.t("unit", ["id": "\(unit.id)"]))
                    .font(Theme.sectionTitle)
                    .foregroundStyle(Theme.ink)
                Text(summary(unit))
                    .font(Theme.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(Theme.label)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .card()
            .accessibilityElement(children: .combine)
        } else {
            Text(store.t("tap_unit"))
                .font(Theme.label)
                .foregroundStyle(Theme.inkMuted)
        }
    }

    private func cell(_ unit: HubUnit) -> some View {
        let moisture: Double = Simulation.chilli.moistureUnit(unit.day)
        let progress: Double
        let color: Color
        let centre: String
        switch unit.mode {
        case .drying?:
            progress = Simulation.dryingProgress(moisture: moisture)
            color = isReady(unit) ? Theme.good : Theme.accent
            centre = String(format: "%.0f%%", moisture)
        case .storing?:
            progress = Double(unit.bags) / Double(Simulation.bagsPerUnit)
            color = Theme.ink
            centre = "\(unit.bags)"
        case .none:
            progress = 0
            color = Theme.ringTrack
            centre = "–"
        }
        let isSelected: Bool = selected == unit.id
        let dimmed: Bool = filter.map { $0 != unit.mode } ?? false
        let spoken: String = ([store.t("unit", ["id": "\(unit.id)"]), summary(unit)] + extra(unit)).joined(separator: ", ")

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selected = unit.id }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    ProgressRing(progress: progress, color: color, lineWidth: 7)
                    Text(centre)
                        .font(Theme.label)
                        .foregroundStyle(unit.mode == .drying ? Theme.wetnessRamp(moisture) : Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(12)
                }
                .aspectRatio(1, contentMode: .fit)
                .overlay(alignment: .topTrailing) {
                    if isReady(unit) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(Theme.label)
                            .foregroundStyle(Theme.good)
                            .background(Circle().fill(Theme.background))
                    }
                }
                Text(verbatim: "\(unit.id)")
                    .font(Theme.caption)
                    .foregroundStyle(isSelected ? Theme.onDark : Theme.inkMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 1)
                    .background(isSelected ? Theme.ink : Theme.clear, in: Capsule())
            }
            .contentShape(Rectangle())
            .opacity(dimmed ? 0.2 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Operator's jobs for today

struct HubTasksCard: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let tasks: [HubTask] = UnitSim.hubTasks
        VStack(alignment: .leading, spacing: 10) {
            Label(store.t("u_tasks"), systemImage: "checklist")
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
            ForEach(tasks) { task in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: task.symbol)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.ink)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    Text(store.t(task.key, task.args))
                        .font(Theme.headline)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Farmers booked for the next free units

struct HubQueueCard: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let list: [HubAssignment] = UnitSim.hubAssignments
        VStack(alignment: .leading, spacing: 0) {
            Label(store.t("u_queue"), systemImage: "person.3.fill")
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
                .padding(.bottom, 6)
            ForEach(list) { item in
                row(item, position: (list.firstIndex(where: { $0.id == item.id }) ?? 0) + 1)
                if item.id != list.last?.id { Divider() }
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    private func row(_ item: HubAssignment, position: Int) -> some View {
        let whenDate: Date = store.now.addingTimeInterval(Double(item.inDays) * Simulation.secondsPerDay)
        let when: String = item.inDays == 0 ? store.t("today") : UnitText.date(whenDate, lang: store.lang)
        let slot: String = store.t("u_gets_unit", ["id": "\(item.unitID)", "when": when])
        let fee: String = store.t("u_load_fee", ["kg": Fmt.kg(item.booking.dryKg),
                                                 "v": Fmt.rupees(UnitSim.fee(forKg: item.booking.dryKg))])
        return HStack(alignment: .center, spacing: 12) {
            Text(verbatim: "\(position)")
                .font(Theme.headline)
                .foregroundStyle(Theme.onDark)
                .frame(width: 36, height: 36)
                .background(Theme.ink, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.booking.farmer + " · " + store.t("Chilli"))
                    .font(Theme.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(slot)
                    .font(Theme.label)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(fee)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}
