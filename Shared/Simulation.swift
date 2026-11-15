import Foundation

/// A nearby market yard shown on the Sell side of Network.
struct Market: Identifiable {
    let id: String
    let nameKey: String
    let distanceKm: Int
    let fixedPrice: Int?      // nil = uses the live Guntur price from SharedState
    let expectedNextWeek: Int
}

/// Drying behaviour of one crop. End points come from the poster
/// (chilli 22 → 14 days, turmeric 36 → 23 days); the curve shape is illustrative.
struct CropProfile {
    let unitDays: Double      // days to dry in a Harvest Protector
    let groundDays: Double    // days to dry on open ground
    let rateUnit: Double
    let rateGround: Double

    func moistureUnit(_ day: Double) -> Double { 10 + 62 * exp(-rateUnit * day) }
    func moistureGround(_ day: Double) -> Double { 10 + 62 * exp(-rateGround * day) }

    func daysLeft(_ day: Double) -> Int { max(0, Int((unitDays - day).rounded(.up))) }
    func isDry(_ day: Double) -> Bool { day >= unitDays }
    /// "Day 12 of 14": whole day number, capped at the last day.
    func dayNumber(_ day: Double) -> Int { min(Int(unitDays), Int(day.rounded(.down))) }
    /// Days a storing unit has been in storage.
    func storageDay(_ day: Double) -> Int { max(0, Int((day - unitDays).rounded(.down))) }

    var curveDaysUnit: [Double] { Array(stride(from: 0.0, through: unitDays, by: 0.5)) }
    var curveDaysGround: [Double] { Array(stride(from: 0.0, through: groundDays, by: 0.5)) }
}

/// One tray level inside a unit (1 = top, nearest the roof).
struct TrayReading: Identifiable {
    let id: Int
    let moisture: Double
    let tempC: Int
    let humidity: Int
}

/// One slot of the short weather forecast.
struct ForecastSlot: Identifiable {
    let id: Int               // hours from now
    let tempC: Int
    let rainPercent: Int
}

/// Weather card verdict: is today good for drying?
enum DryingVerdict { case good, watch, bad }

/// One unit in the hub yard (hub operator's view).
struct HubUnit: Identifiable {
    let id: Int
    let mode: Mode?           // nil = empty
    let day: Double           // drying day (drying units only)
    let bags: Int             // bags stored (storing units only)
}

/// Scripted, offline simulation.
enum Simulation {

    static let secondsPerDay: TimeInterval = 86_400

    static let startMoisture = 72.0
    static let targetMoisture = 11.0

    // MARK: Crops
    static let chilli = CropProfile(unitDays: 14, groundDays: 22, rateUnit: 0.295, rateGround: 0.188)
    static let turmeric = CropProfile(unitDays: 23, groundDays: 36, rateUnit: 0.1794, rateGround: 0.1146)

    static func profile(for crop: String) -> CropProfile {
        crop == "Turmeric" ? turmeric : chilli
    }

    // Chilli shortcuts (Unit A drives the advice, the widget and the notifications).
    static let unitDryingDays = chilli.unitDays
    static let groundDryingDays = chilli.groundDays
    static func moistureUnit(_ day: Double) -> Double { chilli.moistureUnit(day) }
    static func moistureGround(_ day: Double) -> Double { chilli.moistureGround(day) }
    static func daysLeft(_ day: Double) -> Int { chilli.daysLeft(day) }
    static func isDry(_ day: Double) -> Bool { chilli.isDry(day) }
    static func dayNumber(_ day: Double) -> Int { chilli.dayNumber(day) }
    static func storageDay(_ day: Double) -> Int { chilli.storageDay(day) }

    // MARK: Time
    static func day(since start: Date, at now: Date) -> Double {
        max(0, now.timeIntervalSince(start) / secondsPerDay)
    }

    static func batchStart(forDay day: Double, at now: Date) -> Date {
        now.addingTimeInterval(-day * secondsPerDay)
    }

    static func moisture(of unit: Unit, at now: Date) -> Double {
        let p = profile(for: unit.crop)
        switch unit.mode {
        case .drying:  return p.moistureUnit(day(since: unit.batchStart, at: now))
        case .storing: return p.moistureUnit(p.unitDays)
        }
    }

    /// 0...1, harvest moisture → target. Drives the ring fill.
    static func dryingProgress(moisture: Double) -> Double {
        min(1, max(0, (startMoisture - moisture) / (startMoisture - targetMoisture)))
    }

    // MARK: Unit (poster: 96 bags of 40 kg)
    static let bagsPerUnit = 96
    static let kgPerBag = 40

    // MARK: Inside a unit (PLACEHOLDERS: tray spread, temperatures, battery)
    /// Lower trays sit in cooler, damper air, so they dry slower.
    static func trays(for unit: Unit, at now: Date, jitter: Int) -> [TrayReading] {
        let m = moisture(of: unit, at: now)
        let drying = unit.mode == .drying
        let spread: [Double] = drying ? [0.72, 0.90, 1.10, 1.28] : [0.99, 1.00, 1.00, 1.01]
        let temps: [Int] = drying ? [48, 47, 45, 43] : [30, 30, 30, 29]
        let humid: [Int] = drying ? [28, 31, 35, 40] : [47, 48, 48, 49]   // storing: around storageHumidity
        return (0..<4).map { i in
            TrayReading(id: i + 1,
                        moisture: 10 + (m - 10) * spread[i],
                        tempC: temps[i] + (i == 0 ? jitter : 0),
                        humidity: humid[i] + jitter)
        }
    }
    static let batteryPercent = 84
    /// Air heated from 31 °C to 46 °C holds far more water, so relative humidity falls to about a third.
    static let dryingChamberHumidity = 32

    /// Next few hours. PLACEHOLDER numbers.
    static func forecast(raining: Bool) -> [ForecastSlot] {
        raining
            ? [ForecastSlot(id: 0, tempC: 31, rainPercent: 90), ForecastSlot(id: 3, tempC: 27, rainPercent: 60),
               ForecastSlot(id: 6, tempC: 26, rainPercent: 20), ForecastSlot(id: 9, tempC: 25, rainPercent: 10)]
            : [ForecastSlot(id: 0, tempC: 31, rainPercent: 5), ForecastSlot(id: 3, tempC: 32, rainPercent: 10),
               ForecastSlot(id: 6, tempC: 29, rainPercent: 10), ForecastSlot(id: 9, tempC: 26, rainPercent: 5)]
    }

    /// PLACEHOLDER weather extras for the Home weather card.
    static let feelsLikeC = 34
    static let windKmh = 12
    static let sunHoursLeft = 6

    /// One-line verdict on the weather card. PLACEHOLDER rule:
    /// rain on the way = bad, humid air = watch, otherwise good.
    static func dryingVerdict(raining: Bool) -> DryingVerdict {
        if raining { return .bad }
        return outsideHumidity > 70 ? .watch : .good
    }

    /// Hub units close enough to dry to collect this week.
    static var hubReadyCount: Int {
        hubUnits.filter { $0.mode == .drying && $0.day >= chilli.unitDays - 2 }.count
    }

    // MARK: Environment (fixed demo values)
    static let outsideTempC = 31
    static let outsideHumidity = 58
    static let storageHumidity = 48          // ±1 jitter is added by the app; well under the ~65-70% mould line
    static let dryingChamberTempC = 46       // NOT in the spec: check against business model
    static let storageTempC = 30             // NOT in the spec: check against business model

    // MARK: Market
    static let harvestPricePer100kg = 6_000  // poster: sold wet at harvest
    static let defaultPriceAlert = 16_000
    static let priceAlertRange = 15_700...17_000
    static let commissionPercent = 1         // poster: 1% on every crop sold through the network

    /// PLACEHOLDER distances, prices and forecasts (not in the spec).
    static let markets: [Market] = [
        Market(id: "guntur", nameKey: "market_guntur", distanceKm: 38, fixedPrice: nil, expectedNextWeek: 16_000),
        Market(id: "khammam", nameKey: "market_khammam", distanceKm: 140, fixedPrice: 15_200, expectedNextWeek: 15_500),
        Market(id: "warangal", nameKey: "market_warangal", distanceKm: 250, fixedPrice: 14_900, expectedNextWeek: 15_000)
    ]

    /// 30 days, oldest first. Index 22 (7 days ago) = 13,000; today = 15,600 (30-day high).
    static let priceHistory30: [Int] = [
        12_400, 12_450, 12_300, 12_500, 12_550, 12_450, 12_600, 12_700, 12_650, 12_550,
        12_700, 12_800, 12_750, 12_850, 12_900, 12_800, 12_950, 12_900, 13_050, 12_950,
        12_900, 12_950, 13_000, 13_200, 13_450, 13_800, 14_200, 14_650, 15_100, 15_600
    ]

    /// Same history with today's point following the live price.
    static func priceHistory(current: Int) -> [Int] {
        var h = priceHistory30
        if !h.isEmpty { h[h.count - 1] = current }
        return h
    }

    // MARK: Hub (poster: 20 units in one yard, 76 t, ₹700 per 100 kg dried)
    /// 20 units x 96 bags x 40 kg = 76.8 t, shown as the poster's 76 t.
    static let hubCapacityTonnes = 76
    static let hubFeePer100kg = 700
    /// PLACEHOLDERS: which units are drying or storing, kg dried this season, farmers served.
    /// Must stay above hubStoredTonnes (what is in storage was dried here this season):
    /// 25 t dried, about 19 t still stored, the rest already sold. Fees = 25,000 / 100 x ₹700 = ₹1,75,000.
    static let hubDriedKgThisSeason = 25_000
    static let hubFarmers = 38
    /// 7 drying + 11 storing + 2 empty = 20. Stored bags total 480 (19.2 t), below the 25 t dried.
    /// Storing units hold one or a few farmers' batches (Unit B: one batch = 24 bags = 960 kg).
    static let hubUnits: [HubUnit] = [
        HubUnit(id: 1, mode: .drying, day: 12, bags: 0),   HubUnit(id: 2, mode: .storing, day: 0, bags: 48),
        HubUnit(id: 3, mode: .storing, day: 0, bags: 24),  HubUnit(id: 4, mode: .drying, day: 3, bags: 0),
        HubUnit(id: 5, mode: .storing, day: 0, bags: 48),  HubUnit(id: 6, mode: .storing, day: 0, bags: 72),
        HubUnit(id: 7, mode: .drying, day: 8, bags: 0),    HubUnit(id: 8, mode: .storing, day: 0, bags: 24),
        HubUnit(id: 9, mode: nil, day: 0, bags: 0),        HubUnit(id: 10, mode: .storing, day: 0, bags: 48),
        HubUnit(id: 11, mode: .drying, day: 10, bags: 0),  HubUnit(id: 12, mode: .storing, day: 0, bags: 24),
        HubUnit(id: 13, mode: .storing, day: 0, bags: 48), HubUnit(id: 14, mode: .drying, day: 1, bags: 0),
        HubUnit(id: 15, mode: .storing, day: 0, bags: 24), HubUnit(id: 16, mode: .drying, day: 6, bags: 0),
        HubUnit(id: 17, mode: .storing, day: 0, bags: 72), HubUnit(id: 18, mode: nil, day: 0, bags: 0),
        HubUnit(id: 19, mode: .storing, day: 0, bags: 48), HubUnit(id: 20, mode: .drying, day: 13, bags: 0)
    ]
    static var hubStoredTonnes: Double {
        Double(hubUnits.reduce(0) { $0 + $1.bags } * kgPerBag) / 1_000
    }
    static var hubFeesThisSeason: Int { hubDriedKgThisSeason / 100 * hubFeePer100kg }

    // MARK: Mamori Eye field card (PLACEHOLDERS; the 62% matches the poster's app mockup)
    static let fieldEfficiencyPercent = 62
    static let soilMoisture: [(depthCm: Int, percent: Int)] = [(10, 24), (30, 31), (60, 36)]

    // MARK: Read-only helpers for the views (all PLACEHOLDER, simulated)

    /// PLACEHOLDER: the fan pulls warm air through the trays only while drying with the vents open.
    static func fanOn(for unit: Unit) -> Bool {
        unit.mode == .drying && unit.vent == .open
    }

    /// PLACEHOLDER: one 150 W panel per unit. About 112 W in clear midday sun at 31 °C
    /// (hot cells lose ~12%); thick cloud before rain cuts it to about a third.
    static let solarPanelWatts = 150
    static func solarWatts(raining: Bool) -> Int { raining ? 38 : 112 }
    static var solarWattsNow: Int { solarWatts(raining: false) }

    /// PLACEHOLDER: energy harvested since sunrise (about 6 h of sun so far on a 150 W panel).
    /// Fan (about 24 W) plus sensors and camera use well under this; the rest charges the battery.
    static let energyTodayWh = 420
    static let fanWatts = 24

    /// PLACEHOLDER: road transport, about ₹1 per km per 100 kg.
    static let transportRupeesPerKmPer100kg = 1
    static func transportCostPer100kg(market: Market) -> Int {
        max(0, market.distanceKm) * transportRupeesPerKmPer100kg
    }
    /// Price at the market minus transport. Guntur stays best: 15,562 vs 15,060 vs 14,650.
    static func netPricePer100kg(market: Market, livePrice: Int) -> Int {
        (market.fixedPrice ?? livePrice) - transportCostPer100kg(market: market)
    }
}
