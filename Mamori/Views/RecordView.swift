import SwiftUI

/// The six batches of this season shown on the Record screen, newest first.
/// Days to dry, grades and sold prices of #1–#5 are from the WIP; dates, weights,
/// colour scores and moisture are PLACEHOLDERS. #5 is the live Unit B and #6 the live Unit A,
/// so their dates and weights come from the store. Every sale happened more than
/// 30 days ago, so no sold price sits on the 30-day price chart.
struct PastBatch: Identifiable {
    let id: Int
    let unitID: String
    let loadedDaysAgo: Int        // ignored for live batches (#5, #6)
    let daysToDry: Int
    let kg: Int                   // dry weight; ignored for live batches
    let grade: String
    let colourScore: Int
    let moisture: Double          // at storage
    let soldPricePer100kg: Int?   // nil = still in storage (Unit B) or drying (Unit A)
    let certCode: String          // PLACEHOLDER certificate suffix

    var isLive: Bool { id >= 5 }

    static let all: [PastBatch] = [
        PastBatch(id: 6, unitID: "A", loadedDaysAgo: 12, daysToDry: 14, kg: 1_000, grade: "A",
                  colourScore: 86, moisture: 11.0, soldPricePer100kg: nil, certCode: "4MQ8"),
        PastBatch(id: 5, unitID: "B", loadedDaysAgo: 23, daysToDry: 14, kg: 960, grade: "A",
                  colourScore: 88, moisture: 11.0, soldPricePer100kg: nil, certCode: "7K3Q"),
        PastBatch(id: 4, unitID: "B", loadedDaysAgo: 58, daysToDry: 13, kg: 980, grade: "A",
                  colourScore: 87, moisture: 10.9, soldPricePer100kg: 14_200, certCode: "2HX5"),
        PastBatch(id: 3, unitID: "A", loadedDaysAgo: 62, daysToDry: 14, kg: 1_000, grade: "A",
                  colourScore: 85, moisture: 11.0, soldPricePer100kg: 13_600, certCode: "9TD1"),
        PastBatch(id: 2, unitID: "B", loadedDaysAgo: 76, daysToDry: 14, kg: 940, grade: "A",
                  colourScore: 84, moisture: 11.1, soldPricePer100kg: 13_100, certCode: "5RW7"),
        PastBatch(id: 1, unitID: "A", loadedDaysAgo: 80, daysToDry: 15, kg: 900, grade: "B",
                  colourScore: 72, moisture: 11.3, soldPricePer100kg: 12_400, certCode: "8LC2")
    ]

    static func find(_ id: Int) -> PastBatch? { all.first { $0.id == id } }

    var certificateID: String {
        "MMR-26-" + unitID + String(format: "%02d", id) + "-" + certCode
    }
}

struct RecordView: View {
    @Environment(AppStore.self) private var store
    @State private var readings = 41_280
    @State private var certBatch: PastBatch? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacing) {
                    Text(store.t("my_season"))
                        .font(Theme.screenTitle)
                        .foregroundStyle(Theme.ink)

                    HStack(spacing: 10) {
                        StatTile(title: store.t("batches"), value: "\(PastBatch.all.count)")
                        StatTile(title: store.t("readings"), value: Fmt.int(readings))
                        StatTile(title: store.t("photos"), value: Fmt.int(1_152))
                    }

                    Text(store.t("past_batches"))
                        .font(Theme.sectionTitle)
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 4)
                    Text(store.t("u_tap_batch"))
                        .font(Theme.caption)
                        .foregroundStyle(Theme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 0) {
                        ForEach(PastBatch.all) { batch in
                            batchButton(batch)
                            if batch.id != PastBatch.all.last?.id { Divider() }
                        }
                    }
                    .card()

                    seasonTotalCard

                    nextSeasonCard

                    unlocksCard

                    Button {
                        certBatch = PastBatch.find(5)
                    } label: {
                        Label(store.t("share_cert"), systemImage: "checkmark.seal.fill")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
                    }
                    .buttonStyle(.plain)
                }
                .padding(Theme.padding)
                // Room for the custom tab bar and the floating mic.
                .padding(.bottom, Theme.scrollBottomInset)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .mamoriToolbar()
            .sheet(item: $certBatch) { batch in
                CertificateView(batchID: batch.id).environment(store)
            }
            .task {
                // Ticks while the screen is open; .task cancels when it disappears.
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(3))
                    if Task.isCancelled { break }
                    withAnimation { readings += 1 }
                }
            }
        }
    }

    // MARK: Batch list

    private func liveUnit(_ batch: PastBatch) -> Unit? {
        batch.isLive ? store.unit(batch.unitID) : nil
    }

    private func kg(_ batch: PastBatch) -> Int {
        liveUnit(batch)?.weightKg ?? batch.kg
    }

    private func loaded(_ batch: PastBatch) -> Date {
        if let u = liveUnit(batch) { return u.batchStart }
        return store.now.addingTimeInterval(-Double(batch.loadedDaysAgo) * Simulation.secondsPerDay)
    }

    private func dryDate(_ batch: PastBatch) -> Date {
        loaded(batch).addingTimeInterval(Double(batch.daysToDry) * Simulation.secondsPerDay)
    }

    /// The batch still drying in Unit A.
    private func isDrying(_ batch: PastBatch) -> Bool {
        guard let u = liveUnit(batch), u.mode == .drying else { return false }
        return !Simulation.isDry(Simulation.day(since: u.batchStart, at: store.now))
    }

    private func batchButton(_ batch: PastBatch) -> some View {
        let drying: Bool = isDrying(batch)
        return Button {
            if drying {
                // Not certified yet: open the live unit instead.
                store.openUnit(batch.unitID)
            } else {
                certBatch = batch
            }
        } label: {
            batchRow(batch, drying: drying)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken(batch, drying: drying))
        .accessibilityAddTraits(.isButton)
    }

    private func dates(_ batch: PastBatch, drying: Bool) -> String {
        let a: String = UnitText.date(loaded(batch), lang: store.lang)
        if drying { return a + " – " + store.t("now") }
        return a + " – " + UnitText.date(dryDate(batch), lang: store.lang)
    }

    private func status(_ batch: PastBatch, drying: Bool) -> String {
        if let price = batch.soldPricePer100kg { return store.t("sold_at", ["v": Fmt.rupees(price)]) }
        return store.t(drying ? "mode_drying" : "mode_storing")
    }

    private func spoken(_ batch: PastBatch, drying: Bool) -> String {
        let dry: String = drying ? store.t("mode_drying") : store.t("days_to_dry", ["d": "\(batch.daysToDry)"])
        return ["#\(batch.id)", store.t("Chilli"), store.t("unit", ["id": batch.unitID]),
                dates(batch, drying: drying), Fmt.kg(kg(batch)), dry,
                store.t("grade", ["g": batch.grade]), status(batch, drying: drying)].joined(separator: ", ")
    }

    private func batchRow(_ batch: PastBatch, drying: Bool) -> some View {
        let dryText: String = drying
            ? store.t("u_tl_today", ["d": "\(Simulation.dayNumber(Simulation.day(since: loaded(batch), at: store.now)))"])
            : store.t("days_to_dry", ["d": "\(batch.daysToDry)"])
        let line2: String = dates(batch, drying: drying) + " · " + Fmt.kg(kg(batch))
        let line3: String = dryText + " · " + store.t("grade", ["g": batch.grade])
        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("#\(batch.id) · " + store.t("Chilli") + " · " + store.t("unit", ["id": batch.unitID]))
                    .font(Theme.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(line2)
                    .font(Theme.label)
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                Text(line3)
                    .font(Theme.label)
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            statusView(batch, drying: drying)
            Image(systemName: "chevron.right")
                .font(Theme.label)
                .foregroundStyle(Theme.inkMuted)
        }
        .padding(.vertical, 10)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func statusView(_ batch: PastBatch, drying: Bool) -> some View {
        if let price = batch.soldPricePer100kg {
            Text(store.t("sold_at", ["v": Fmt.rupees(price)]))
                .font(Theme.label)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        } else {
            let fill: Color = drying ? Theme.accent : Theme.ink
            let ink: Color = drying ? Theme.onAccent : Theme.onDark
            Text(store.t(drying ? "mode_drying" : "mode_storing"))
                .font(Theme.label)
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(fill, in: Capsule())
        }
    }

    // MARK: Season totals (add up the list above)

    private var seasonTotalCard: some View {
        let all: [PastBatch] = PastBatch.all
        let totalKg: Int = all.reduce(0) { $0 + kg($1) }
        let sold: [PastBatch] = all.filter { $0.soldPricePer100kg != nil }
        let soldKg: Int = sold.reduce(0) { $0 + kg($1) }
        let revenue: Int = sold.reduce(0) { $0 + kg($1) * ($1.soldPricePer100kg ?? 0) / 100 }
        let finished: [PastBatch] = all.filter { !isDrying($0) }
        let dayTotal: Int = finished.reduce(0) { $0 + $1.daysToDry }
        let avg: Double = finished.isEmpty ? 0 : Double(dayTotal) / Double(finished.count)
        let totalLine: String = store.t("u_season_total", ["n": "\(all.count)", "kg": Fmt.kg(totalKg)])
        let soldLine: String = store.t("u_season_sold", ["n": "\(sold.count)", "kg": Fmt.kg(soldKg),
                                                         "v": Fmt.rupees(revenue)])
        let avgLine: String = store.t("u_avg_days", ["d": String(format: "%.1f", avg),
                                                     "g": "\(Int(Simulation.groundDryingDays))"])
        return VStack(alignment: .leading, spacing: 8) {
            Label(store.t("u_season"), systemImage: "sum")
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
            Text(totalLine)
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(soldLine)
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(avgLine)
                .font(Theme.label)
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    // Poster: "Learns every season". PLACEHOLDER advice, built from batch 1 above.
    private var nextSeasonCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(store.t("next_season"), systemImage: "sparkles")
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
            Text(store.t("next_season_body"))
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card()
    }

    private var unlocksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.t("unlocks_title"))
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
            unlockRow("cart.fill", store.t("unlock_buyers"))
            unlockRow("building.columns.fill", store.t("unlock_banks"))
            unlockRow("sparkles", store.t("unlock_advice"))
        }
        .card()
    }

    private func unlockRow(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(Theme.headline)
                .foregroundStyle(Theme.onAccent)
                .frame(width: 40, height: 40)
                .background(Theme.accent, in: Circle())
            Text(text)
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Quality certificate (static sheet, no PDF)

struct CertificateView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    /// Which batch of the season. 5 = the live Unit B (the default, as before).
    var batchID: Int = 5

    private var batch: PastBatch? { PastBatch.find(batchID) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(Theme.heroNumber)
                            .foregroundStyle(Theme.good)
                            .accessibilityHidden(true)
                        Text(store.t("cert_title"))
                            .font(Theme.screenTitle)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                    }

                    if batchID == 5 || batch == nil {
                        liveRows
                    } else if let b = batch {
                        pastRows(b)
                    }

                    Text(store.t("cert_footer"))
                        .font(Theme.caption)
                        .foregroundStyle(Theme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Theme.padding)
            }
            .background(Theme.background)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.t("done")) { dismiss() }
                }
            }
        }
    }

    /// Batch #5, read live from Unit B (unchanged from the WIP, plus the certificate ID).
    private var liveRows: some View {
        let unit: Unit = store.unit("B") ?? store.unitA
        let dryEnd: Date = unit.batchStart.addingTimeInterval(Simulation.unitDryingDays * Simulation.secondsPerDay)
        let certID: String = PastBatch.find(5)?.certificateID ?? "MMR-26-B05"
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                row(store.t("cert_id"), certID)
                Divider()
                row(store.t("cert_batch"),
                    "#5 · " + store.t(unit.crop) + " · " + store.t("unit", ["id": unit.id]))
                Divider()
                row(store.t("grade", ["g": ""]).trimmingCharacters(in: .whitespaces),
                    unit.grade + " · " + store.t("colour") + " \(unit.colourScore)/100")
                Divider()
                row(store.t("cert_moisture"), Fmt.percent1(Simulation.moisture(of: unit, at: store.now)))
                Divider()
            }
            row(store.t("cert_drying"),
                date(unit.batchStart) + " – " + date(dryEnd) + " (" + store.t("days_n", ["d": "14"]) + ")")
            Divider()
            row(store.t("cert_stored"), date(dryEnd))
            Divider()
            row(store.t("weight"),
                Fmt.kg(unit.weightKg) + " · " + store.t("bags", ["n": "\(unit.bags ?? 24)"]))
            Divider()
            row(store.t("mould_risk"), store.t(unit.mouldRisk))
        }
        .card()
    }

    /// Batches #1–#4 (sold) and #6, from the season list.
    private func pastRows(_ b: PastBatch) -> some View {
        // #6 is the live Unit A: take its real start, weight and moisture.
        let live: Unit? = b.isLive ? store.unit(b.unitID) : nil
        let fallbackStart: Date = store.now.addingTimeInterval(-Double(b.loadedDaysAgo) * Simulation.secondsPerDay)
        let start: Date = live?.batchStart ?? fallbackStart
        let dryEnd: Date = start.addingTimeInterval(Double(b.daysToDry) * Simulation.secondsPerDay)
        let kg: Int = live?.weightKg ?? b.kg
        let bags: Int = UnitSim.bagsFor(kg: kg)
        let moisture: Double = live.map { Simulation.moisture(of: $0, at: store.now) } ?? b.moisture
        let sold: String? = b.soldPricePer100kg.map { store.t("sold_at", ["v": Fmt.rupees($0)]) }
        let daysText: String = store.t("days_n", ["d": "\(b.daysToDry)"])
        let dryingText: String = date(start) + " – " + date(dryEnd) + " (" + daysText + ")"
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                row(store.t("cert_id"), b.certificateID)
                Divider()
                row(store.t("cert_batch"),
                    "#\(b.id) · " + store.t("Chilli") + " · " + store.t("unit", ["id": b.unitID]))
                Divider()
                row(store.t("grade", ["g": ""]).trimmingCharacters(in: .whitespaces),
                    b.grade + " · " + store.t("colour") + " \(b.colourScore)/100")
                Divider()
                row(store.t("cert_moisture"), Fmt.percent1(moisture))
                Divider()
            }
            row(store.t("cert_drying"), dryingText)
            Divider()
            row(store.t("cert_stored"), date(dryEnd))
            Divider()
            row(store.t("weight"), Fmt.kg(kg) + " · " + store.t("bags", ["n": "\(bags)"]))
            Divider()
            row(store.t("mould_risk"), store.t("Low"))
            if let sold {
                Divider()
                row(store.t("u_sale"), sold)
            }
        }
        .card()
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.caption)
                .foregroundStyle(Theme.inkMuted)
            Text(value)
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    private func date(_ d: Date) -> String {
        d.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(L10n.locale(store.lang)))
    }
}
