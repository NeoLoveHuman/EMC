import Foundation
import Observation

enum AppTab: Hashable { case home, units, network, record }

/// Switches for parts of the app that are built but kept out of the demo.
enum Features {
    /// Seeds / fertiliser / expert shop. Hidden: the poster positions Mamori against input sellers.
    static let showBuy = false
}

/// The scripted questions behind the mic. No real speech recognition:
/// it would fail in a noisy hall, so every answer is computed from the live state.
enum VoiceQuestion: String, CaseIterable, Identifiable {
    case farm, crop, rain, sell, markets, unit, trays, hub, season
    var id: String { rawValue }
    var key: String { "q_\(rawValue)" }
}

/// Where the farmer is when they press the mic. Decides which questions it answers.
enum VoiceContext: Equatable {
    case home, units, unit(String), hub, network, record

    /// Script for this screen: each mic press plays the next one.
    var script: [VoiceQuestion] {
        switch self {
        case .home:    return [.farm, .rain, .sell]
        case .units:   return [.crop, .rain, .sell]
        case .unit:    return [.unit, .trays, .rain]
        case .hub:     return [.hub, .markets]
        case .network: return [.sell, .markets]
        case .record:  return [.season, .sell]
        }
    }

    var stepKey: String {
        switch self {
        case .home: return "home"
        case .units: return "units"
        case .unit(let id): return "unit_" + id
        case .hub: return "hub"
        case .network: return "network"
        case .record: return "record"
        }
    }
}

/// The app's single source of truth. Every change to SharedState goes
/// through `update`, which saves to the App Group and reloads the widget.
@MainActor
@Observable
final class AppStore {

    private(set) var state: SharedState

    // Live, non-persisted UI state
    var now: Date = Date()
    var humidityJitter: Int = 0
    var notificationDelay: Double = 5
    var selectedTab: AppTab = .home
    var deepLinkUnitID: String?
    var unreadAlerts: Int = 0
    var showDemoPanel: Bool = false
    var focusedUnitID: String?      // unit detail currently open, if any

    var unitsShowHub: Bool = false  // Units tab: false = my farm, true = hub

    // Voice
    var voiceQuestion: String?
    var voiceAnswer: String?
    var voiceThinking: Bool = false
    var currentVoiceQuestion: VoiceQuestion?
    var speakAlerts: Bool = false
    var offerSent: Bool = false

    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private var voiceTask: Task<Void, Never>?
    @ObservationIgnored private var voiceSteps: [String: Int] = [:]

    /// Every cold launch starts from a fresh seed (Unit A day 12, ~11.8%), because the
    /// seed is stored with real dates and would otherwise read "ready" days later.
    /// Only the farmer's language and price-alert target are carried over.
    init() {
        var seed = SharedState.seed()
        if let saved = SharedStore.load() {
            let known = L10n.languages.contains { $0.code == saved.language }
            seed.language = known ? saved.language : "en"
            seed.priceAlertTarget = saved.priceAlertTarget
        }
        state = seed
        SharedStore.save(seed)
    }

    /// 1 s clock so moisture, vent animation and "min ago" stay live;
    /// storage humidity jitters ±1 every 3 s so the screen looks alive.
    func start() {
        guard ticker == nil else { return }
        ticker = Task { [weak self] in
            var tick = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                self.now = Date()
                tick += 1
                if tick % 3 == 0 { self.humidityJitter = Int.random(in: -1...1) }
            }
        }
    }

    // MARK: - Read helpers

    var lang: String { state.language }

    func t(_ key: String, _ args: [String: String] = [:]) -> String {
        L10n.t(key, state.language, args)
    }

    func unit(_ id: String) -> Unit? { state.unit(id) }

    var unitA: Unit { state.unit("A") ?? SharedState.seedUnitA() }

    /// Live-looking readings inside a unit (±1 around the fixed demo values).
    func insideHumidity(_ unit: Unit) -> Int {
        (unit.mode == .drying ? Simulation.dryingChamberHumidity : Simulation.storageHumidity) + humidityJitter
    }
    func insideTemp(_ unit: Unit) -> Int {
        (unit.mode == .drying ? Simulation.dryingChamberTempC : Simulation.storageTempC) + humidityJitter
    }

    private var unitADay: Double { Simulation.day(since: unitA.batchStart, at: now) }

    /// Unit A's drying day right now (e.g. 12.0), for the demo panel status.
    var unitADayNow: Double { unitADay }

    /// Unit A's moisture right now (e.g. 11.8), for the demo panel status.
    var unitAMoistureNow: Double { Simulation.moisture(of: unitA, at: now) }

    // MARK: - Rain countdown

    /// Minutes until rain at a given time: 40 when the scene fires, then falls by
    /// real minutes, never below 1. nil = no rain expected.
    func rainMinutesLeft(at date: Date) -> Int? { state.rainMinutesLeft(at: date) }

    /// Same, on the app's 1 s clock, so views refresh by themselves.
    var rainMinutesLeftNow: Int? { state.rainMinutesLeft(at: now) }

    /// One-sentence hold / sell advice, used on the dashboard and the Sell side.
    var adviceSentence: String { adviceSentence(in: lang) }

    private func adviceSentence(in l: String) -> String {
        if state.advice == .sell { return L10n.t("advice_sell", l) }
        let left = Simulation.daysLeft(unitADay)
        return left >= 2 ? L10n.t("advice_hold", l, ["d": "\(left)"]) : L10n.t("advice_hold_soon", l)
    }

    /// The facts behind the advice, shown as a short "why" list.
    var adviceReasons: [String] {
        var reasons: [String] = []
        let left = Simulation.daysLeft(unitADay)
        if Simulation.isDry(unitADay) {
            reasons.append(t("why_dry"))
        } else if left >= 2 {
            reasons.append(t("why_days", ["d": "\(left)"]))
        } else {
            reasons.append(t("why_almost"))
        }
        if state.advice == .sell {
            reasons.append(t("why_high"))
        } else {
            reasons.append(t("why_price_up", ["p": "\(state.priceChangePercent)"]))
        }
        if let mins = rainMinutesLeftNow {
            reasons.append(t("rain_in", ["n": "\(mins)"]))
        } else {
            reasons.append(t("no_rain"))
        }
        return reasons
    }

    // MARK: - Voice assistant

    /// Which screen the mic is answering for.
    var voiceContext: VoiceContext {
        switch selectedTab {
        case .home: return .home
        case .units:
            if unitsShowHub { return .hub }
            if let id = focusedUnitID, unit(id) != nil { return .unit(id) }
            return .units
        case .network: return .network
        case .record: return .record
        }
    }

    /// Follow-up chips under an answer: the rest of this screen's script.
    var voiceSuggestions: [VoiceQuestion] {
        voiceContext.script.filter { $0 != currentVoiceQuestion }
    }

    private func cropAnswer(in l: String) -> String {
        let args = [
            "crop": L10n.t(unitA.crop, l),
            "m": String(format: "%.1f", Simulation.moisture(of: unitA, at: now)),
            "d": "\(Simulation.daysLeft(unitADay))",
            "n": "\(state.units.count)"
        ]
        if Simulation.isDry(unitADay) { return L10n.t("ans_crop_dry", l, args) }
        return L10n.t(Simulation.daysLeft(unitADay) >= 2 ? "ans_crop" : "ans_crop_soon", l, args)
    }

    private func rainAnswer(in l: String) -> String {
        if let mins = rainMinutesLeftNow { return L10n.t("ans_rain", l, ["n": "\(mins)"]) }
        return L10n.t("ans_no_rain", l)
    }

    private func sellAnswer(in l: String) -> String {
        let worth = unitA.weightKg * state.pricePer100kg / 100
        return adviceSentence(in: l) + " " + L10n.t("ans_worth", l, ["v": Fmt.rupees(worth)])
    }

    private func marketsAnswer(in l: String) -> String {
        let guntur = Simulation.markets.first { $0.fixedPrice == nil }
        let second = Simulation.markets.first { $0.fixedPrice != nil }
        return L10n.t("ans_markets", l, [
            "v": Fmt.rupees(state.pricePer100kg),
            "k": "\(guntur?.distanceKm ?? 38)",
            "v2": Fmt.rupees(second?.fixedPrice ?? 15_200)
        ])
    }

    private func unitAnswer(_ u: Unit, in l: String) -> String {
        let p = Simulation.profile(for: u.crop)
        let day = Simulation.day(since: u.batchStart, at: now)
        let status: String
        switch u.mode {
        case .storing:
            status = L10n.t("in_storage_day", l, ["d": "\(p.storageDay(day))"])
        case .drying:
            status = p.isDry(day) ? L10n.t("ready", l)
                                  : L10n.t("day_of", l, ["d": "\(p.dayNumber(day))", "t": "\(Int(p.unitDays))"])
        }
        let ventKey: String
        switch u.ventDisplay(at: now) {
        case .open: ventKey = "vent_open"
        case .closing: ventKey = "vent_closing"
        case .closed: ventKey = "vent_closed"
        }
        return L10n.t("ans_unit", l, [
            "id": u.id,
            "crop": L10n.t(u.crop, l),
            "m": String(format: "%.1f", Simulation.moisture(of: u, at: now)),
            "status": status,
            "vent": L10n.t(ventKey, l)
        ])
    }

    /// The unit the farmer is looking at, or Unit A.
    private var focusedUnit: Unit {
        if let id = focusedUnitID, let u = unit(id) { return u }
        return unitA
    }

    private func traysAnswer(in l: String) -> String {
        let u = focusedUnit
        let trays = Simulation.trays(for: u, at: now, jitter: 0)
        guard let wettest = trays.max(by: { $0.moisture < $1.moisture }),
              let top = trays.first else { return cropAnswer(in: l) }
        let spread = wettest.moisture - top.moisture
        if u.mode == .storing || spread < 0.3 {
            return L10n.t("ans_trays_even", l, ["m": String(format: "%.1f", Simulation.moisture(of: u, at: now))])
        }
        return L10n.t("ans_trays", l, [
            "w": "\(wettest.id)",
            "m": String(format: "%.1f", wettest.moisture),
            "d": String(format: "%.1f", spread)
        ])
    }

    private func hubAnswer(in l: String) -> String {
        let units = Simulation.hubUnits
        return L10n.t("ans_hub", l, [
            "d": "\(units.filter { $0.mode == .drying }.count)",
            "s": "\(units.filter { $0.mode == .storing }.count)",
            "t": String(format: "%.1f", Simulation.hubStoredTonnes),
            "r": "\(Simulation.hubReadyCount)"
        ])
    }

    private func answer(_ q: VoiceQuestion, in l: String) -> String {
        switch q {
        case .farm:    return [cropAnswer(in: l), rainAnswer(in: l), adviceSentence(in: l)].joined(separator: " ")
        case .crop:    return cropAnswer(in: l)
        case .rain:    return rainAnswer(in: l)
        case .sell:    return sellAnswer(in: l)
        case .markets: return marketsAnswer(in: l)
        case .unit:    return unitAnswer(focusedUnit, in: l)
        case .trays:   return traysAnswer(in: l)
        case .hub:     return hubAnswer(in: l)
        case .season:  return L10n.t("ans_record", l, ["b": "6", "r": Fmt.int(41_280)])
        }
    }

    /// Shows the question at once, "thinks" for 0.8 s, then shows the answer in
    /// the app language and speaks it (in English if the phone has no voice for it).
    func ask(_ q: VoiceQuestion) {
        voiceTask?.cancel()
        SpeechService.shared.stop()
        currentVoiceQuestion = q
        voiceQuestion = t(q.key)
        voiceAnswer = nil
        voiceThinking = true
        voiceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(800))
            guard let self, !Task.isCancelled else { return }
            let l = self.lang
            self.voiceThinking = false
            self.voiceAnswer = self.answer(q, in: l)
            let speakLang = SpeechService.shared.hasVoice(l) ? l : "en"
            let spoken = self.answer(q, in: speakLang)
                .replacingOccurrences(of: "₹", with: L10n.t("rupees_spoken", speakLang))
            SpeechService.shared.speak(spoken, lang: speakLang)
        }
    }

    /// Mic released: plays the next question in this screen's script, so
    /// pressing twice never repeats the same sentence.
    func askNext() {
        let ctx = voiceContext
        let script = ctx.script
        guard !script.isEmpty else { return }
        let step = voiceSteps[ctx.stepKey] ?? 0
        voiceSteps[ctx.stepKey] = step + 1
        ask(script[step % script.count])
    }

    func dismissVoice() {
        voiceTask?.cancel()
        voiceTask = nil
        SpeechService.shared.stop()
        voiceThinking = false
        voiceQuestion = nil
        voiceAnswer = nil
        currentVoiceQuestion = nil
    }

    // MARK: - Navigation

    func openUnit(_ id: String) {
        selectedTab = .units
        unitsShowHub = false
        deepLinkUnitID = id
    }

    // MARK: - Writes

    private func update(_ change: (inout SharedState) -> Void) {
        var s = state
        change(&s)
        state = s
        SharedStore.save(s)
    }

    private func updateUnit(_ id: String, _ change: @escaping (inout Unit) -> Void) {
        update { s in
            if let i = s.units.firstIndex(where: { $0.id == id }) { change(&s.units[i]) }
        }
    }

    func setLanguage(_ code: String) {
        dismissVoice()      // an answer in the old language must not stay on screen
        update { $0.language = code }
    }

    func setPriceAlert(_ target: Int?) {
        update { $0.priceAlertTarget = target }
    }

    /// Manual toggle. Closing plays a 3 s "closing" phase in the app;
    /// the stored target is .closed straight away so the widget reads "closed".
    func setVents(open: Bool, unitID: String) {
        updateUnit(unitID) { u in
            if open {
                u.vent = .open
                u.ventClosingUntil = nil
            } else if u.vent != .closed {
                u.vent = .closed
                u.ventClosingUntil = Date().addingTimeInterval(3)
            }
        }
    }

    // MARK: - Demo actions (hidden panel)

    func demoRain() {
        update {
            $0.rainInMinutes = 40
            $0.rainStartedAt = Date()
        }
        // Every drying unit closes, not only A: an open vent in the rain would look wrong.
        for unit in state.units where unit.mode == .drying {
            setVents(open: false, unitID: unit.id)
        }
        pushAlert(.rain)
    }

    func demoAlmostDry() {
        updateUnit("A") { $0.batchStart = Simulation.batchStart(forDay: 13.5, at: Date()) }
        pushAlert(.almostDry)
    }

    func demoPriceJump() {
        update {
            $0.pricePer100kg = 15_600
            $0.advice = .sell
        }
        updateUnit("A") { $0.batchStart = Simulation.batchStart(forDay: 14, at: Date()) }
        pushAlert(.priceJump)
    }

    /// The Guntur price reaches the farmer's alert target (default ₹16,000).
    func demoPriceTargetHit() {
        let target = state.priceAlertTarget ?? Simulation.defaultPriceAlert
        update {
            $0.priceAlertTarget = target
            $0.pricePer100kg = target
            $0.advice = .sell
        }
        updateUnit("A") { $0.batchStart = Simulation.batchStart(forDay: 14, at: Date()) }
        pushAlert(.priceTarget, value: target)
    }

    func resetDemo() {
        NotificationService.shared.clearAll()
        SpeechService.shared.stop()
        let seed = SharedState.seed()
        state = seed
        SharedStore.save(seed)
        unreadAlerts = 0
        selectedTab = .home
        unitsShowHub = false
        focusedUnitID = nil
        voiceSteps = [:]
        dismissVoice()
        offerSent = false
        now = Date()
    }

    private func pushAlert(_ kind: AlertKind, value: Int? = nil) {
        update { $0.alerts.insert(AlertItem(kind: kind, date: Date(), value: value), at: 0) }
        unreadAlerts += 1
        // Text is taken in the current language at the moment of scheduling.
        NotificationService.shared.schedule(title: t(kind.titleKey),
                                            body: t(kind.bodyKey, ["v": Fmt.rupees(value ?? 0)]),
                                            after: notificationDelay,
                                            lang: lang)
    }

    // MARK: - Deep link from the widget: mamori://unit/A

    func handle(url: URL) {
        guard url.scheme == "mamori" else { return }
        let id = url.lastPathComponent
        openUnit(id.isEmpty ? "A" : id)
    }
}
