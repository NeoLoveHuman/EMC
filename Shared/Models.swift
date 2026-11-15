import Foundation

enum Mode: String, Codable { case drying, storing }
enum VentState: String, Codable { case open, closing, closed }
enum Advice: String, Codable { case hold, sell }

struct Unit: Codable, Identifiable, Equatable {
    var id: String            // "A", "B", "C"
    var crop: String          // "Chilli" (also a translation key)
    var mode: Mode
    var batchStart: Date      // drying start
    var weightKg: Int
    var vent: VentState       // target state (.open or .closed)
    var grade: String         // "A"
    var colourScore: Int      // 0-100
    var mouldRisk: String     // "Low" (also a translation key)
    var bags: Int?
    var ventClosingUntil: Date?   // while now < this, the UI shows "closing"
    var gradedAt: Date

    /// What the screen should show right now (adds the 3 s "closing" phase).
    func ventDisplay(at now: Date) -> VentState {
        if let until = ventClosingUntil, now < until { return .closing }
        return vent
    }
}

enum AlertKind: String, Codable {
    case rain, almostDry, priceJump, priceTarget, dryingStarted, storageCheck

    var titleKey: String { "alert_\(rawValue)_title" }
    /// storageCheck uses a v2 key: the old text in Strings.swift said 58% humidity,
    /// which no longer matches Simulation.storageHumidity (48%).
    var bodyKey: String {
        self == .storageCheck ? "alert_storageCheck_body_v2" : "alert_\(rawValue)_body"
    }

    var symbol: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .almostDry: return "sun.max.fill"
        case .priceJump: return "chart.line.uptrend.xyaxis"
        case .priceTarget: return "bell.badge.fill"
        case .dryingStarted: return "play.circle.fill"
        case .storageCheck: return "checkmark.shield.fill"
        }
    }
}

struct AlertItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var kind: AlertKind
    var date: Date
    var value: Int? = nil     // ₹ amount for price alerts, fills {v} in the text
}

struct SharedState: Codable, Equatable {
    var units: [Unit]
    var pricePer100kg: Int        // ₹, Guntur yard
    var lastWeekPricePer100kg: Int
    var advice: Advice
    var rainInMinutes: Int?       // nil = no rain expected
    var alerts: [AlertItem]       // newest first
    var language: String          // "en", "te", "hi", "ja"
    var priceAlertTarget: Int?    // "notify me at ₹16,000"; nil = no alert set
    /// When the rain scene fired. Optional, so state saved before this field existed still decodes.
    var rainStartedAt: Date? = nil

    /// Minutes until rain, counting down in real minutes from rainInMinutes, never below 1.
    /// nil = no rain expected.
    func rainMinutesLeft(at now: Date) -> Int? {
        guard let total = rainInMinutes else { return nil }
        guard let start = rainStartedAt else { return max(1, total) }
        let elapsedMinutes = Int(max(0, now.timeIntervalSince(start)) / 60)
        return max(1, total - elapsedMinutes)
    }

    func unit(_ id: String) -> Unit? { units.first { $0.id == id } }

    var priceChangePercent: Int {
        guard lastWeekPricePer100kg > 0 else { return 0 }
        let change = Double(pricePer100kg - lastWeekPricePer100kg) / Double(lastWeekPricePer100kg) * 100
        return Int(change.rounded())
    }

    var totalWeightKg: Int { units.reduce(0) { $0 + $1.weightKg } }
}

extension SharedState {
    /// Unit A as seeded: chilli, day 12 of 14, about 11.8%. Also the safe fallback
    /// wherever Unit A is missing (no array indexing needed).
    static func seedUnitA(now: Date = Date()) -> Unit {
        Unit(id: "A", crop: "Chilli", mode: .drying,
             batchStart: now.addingTimeInterval(-12 * Simulation.secondsPerDay),
             weightKg: 1_000, vent: .open,
             grade: "A", colourScore: 86, mouldRisk: "Low",
             bags: nil, ventClosingUntil: nil,
             gradedAt: now.addingTimeInterval(-4 * 60))
    }

    /// Seed / reset state. Units A and B and the market numbers come from the
    /// build spec, section 4. Unit C is a PLACEHOLDER added for the dashboard:
    /// check its numbers against the business model.
    static func seed(now: Date = Date()) -> SharedState {
        let day = Simulation.secondsPerDay
        return SharedState(
            units: [
                seedUnitA(now: now),
                Unit(id: "B", crop: "Chilli", mode: .storing,
                     batchStart: now.addingTimeInterval(-23 * day),   // dried 14 days, stored 9
                     weightKg: 960, vent: .closed,
                     grade: "A", colourScore: 88, mouldRisk: "Low",
                     bags: 24, ventClosingUntil: nil,
                     gradedAt: now.addingTimeInterval(-11 * 60)),
                Unit(id: "C", crop: "Turmeric", mode: .drying,
                     batchStart: now.addingTimeInterval(-5 * day),    // day 5 of 23, about 35%
                     weightKg: 800, vent: .open,
                     grade: "A", colourScore: 81, mouldRisk: "Low",
                     bags: nil, ventClosingUntil: nil,
                     gradedAt: now.addingTimeInterval(-7 * 60))
            ],
            pricePer100kg: 15_600,
            lastWeekPricePer100kg: 13_000,
            advice: .hold,
            rainInMinutes: nil,
            alerts: [
                AlertItem(kind: .storageCheck, date: now.addingTimeInterval(-3 * 3600)),
                AlertItem(kind: .dryingStarted, date: now.addingTimeInterval(-12 * day))
            ],
            language: "en",
            priceAlertTarget: nil
        )
    }
}
