import Foundation

/// One farmer waiting for a hub unit.
struct HubBooking: Identifiable {
    let id: Int
    let farmer: String
    let dryKg: Int            // expected dry weight, which is what the hub fee is charged on
}

/// Which free (or soon free) unit a booking gets, and in how many days.
struct HubAssignment: Identifiable {
    let id: Int               // booking id
    let booking: HubBooking
    let unitID: Int
    let inDays: Int           // 0 = today
}

/// One job for the hub operator today.
struct HubTask: Identifiable {
    let id: Int
    let symbol: String
    let key: String
    let args: [String: String]
}

/// Simulated extras for the unit, hub, sell and record screens (Builder C).
/// Everything here is derived from Simulation so no two numbers on screen disagree.
/// Every invented figure is marked PLACEHOLDER: check against the business model.
enum UnitSim {

    // MARK: - Power (each unit has its own panel, battery and DC fan)

    /// PLACEHOLDER: panel rating per unit.
    static let panelRatedWatts: Int = 120
    /// PLACEHOLDER: midday clear sky ≈ 78% of rating (a hot panel loses output);
    /// heavy cloud before rain ≈ 20%.
    static func panelWatts(raining: Bool) -> Int {
        raining ? 24 : 94
    }
    /// PLACEHOLDER: fan speed. Runs only while drying with the vents open
    /// (pulls dry warm air through the trays). Off when vents are shut or the unit is storing.
    static func fanSpeedPercent(unit: Unit, vent: VentState) -> Int {
        guard unit.mode == .drying, vent == .open else { return 0 }
        return 70
    }
    /// PLACEHOLDER: fan rated 36 W; fan power scales with speed cubed, plus 3 W for sensors and camera.
    static func loadWatts(fanPercent: Int) -> Double {
        let s: Double = Double(fanPercent) / 100
        return 36 * s * s * s + 3
    }
    static func isCharging(unit: Unit, vent: VentState, raining: Bool) -> Bool {
        Double(panelWatts(raining: raining)) > loadWatts(fanPercent: fanSpeedPercent(unit: unit, vent: vent))
    }

    // MARK: - Storage

    /// PLACEHOLDER: relative humidity above which mould can grow on dry chilli (water activity ≈ 0.70).
    static let mouldHumidityLine: Int = 70
    /// PLACEHOLDER: dry chilli at 11% kept below 65% humidity holds its grade about 6 months.
    static let safeStorageDays: Int = 180
    static let safeHumidity: Int = 65

    /// Safe storage days left for a crop that has been in storage `storedDays`.
    /// Humid air (above 65%) cuts the horizon to a third. PLACEHOLDER rule.
    static func safeDaysLeft(storedDays: Int, humidity: Int) -> Int {
        let horizon: Int = humidity > safeHumidity ? safeStorageDays / 3 : safeStorageDays
        return max(0, horizon - storedDays)
    }

    /// Bags needed for a given dry weight (40 kg bags).
    static func bagsFor(kg: Int) -> Int {
        let per: Int = max(1, Simulation.kgPerBag)
        return (kg + per - 1) / per
    }

    // MARK: - Hub

    /// PLACEHOLDER: who is using each hub unit (nil = empty). Indexed by unit id.
    static let hubFarmers: [Int: String] = [
        1: "K. Ramesh", 2: "P. Lakshmi", 3: "S. Venkat", 4: "B. Anjali", 5: "M. Srinu",
        6: "G. Padma", 7: "R. Naidu", 8: "T. Suresh", 10: "V. Kavitha", 11: "D. Raju",
        12: "N. Sarada", 13: "Ch. Prasad", 14: "A. Mallesh", 15: "Y. Swapna", 16: "J. Krishna",
        17: "L. Bhavani", 19: "E. Ravi", 20: "K. Sujatha"
    ]

    /// PLACEHOLDER: expected dry weight in each drying hub unit (≈ one Unit A batch each).
    static let hubDryingLoadKg: [Int: Int] = [
        1: 1_000, 4: 900, 7: 1_100, 11: 800, 14: 1_000, 16: 950, 20: 1_050
    ]

    /// PLACEHOLDER: days each storing hub unit has been in storage.
    static let hubStorageDays: [Int: Int] = [
        2: 31, 3: 27, 5: 24, 6: 20, 8: 16, 10: 14, 12: 12, 13: 7, 15: 6, 17: 4, 19: 1
    ]

    /// PLACEHOLDER: storage humidity in the hub units (same value as Unit B).
    static let hubStorageHumidity: Int = Simulation.storageHumidity

    /// PLACEHOLDER: farmers booked for the next free units, first come first served.
    static let hubBookings: [HubBooking] = [
        HubBooking(id: 1, farmer: "P. Venkatesh", dryKg: 1_000),
        HubBooking(id: 2, farmer: "S. Anitha", dryKg: 900),
        HubBooking(id: 3, farmer: "M. Naresh", dryKg: 1_050),
        HubBooking(id: 4, farmer: "B. Rani", dryKg: 950)
    ]

    /// PLACEHOLDER: a unit is cleaned and reloaded the day after it is bagged.
    static let turnaroundDays: Int = 1

    static func farmer(_ id: Int) -> String {
        hubFarmers[id] ?? "–"
    }

    static func dryingLoadKg(_ id: Int) -> Int {
        hubDryingLoadKg[id] ?? 1_000
    }

    static func storageDays(_ id: Int) -> Int {
        hubStorageDays[id] ?? 0
    }

    static func fee(forKg kg: Int) -> Int {
        kg * Simulation.hubFeePer100kg / 100
    }

    /// Fees still to bill for the units drying now.
    static var hubFeesToBill: Int {
        let drying: [HubUnit] = Simulation.hubUnits.filter { $0.mode == .drying }
        let kg: Int = drying.reduce(0) { $0 + dryingLoadKg($1.id) }
        return fee(forKg: kg)
    }

    /// Bookings matched to units: empty units today, then drying units in the order they finish.
    static var hubAssignments: [HubAssignment] {
        let units: [HubUnit] = Simulation.hubUnits
        var slots: [(unit: Int, days: Int)] = units.filter { $0.mode == nil }.map { (unit: $0.id, days: 0) }
        let drying: [HubUnit] = units.filter { $0.mode == .drying }
        let soon: [(unit: Int, days: Int)] = drying.map { u in
            (unit: u.id, days: Simulation.chilli.daysLeft(u.day) + turnaroundDays)
        }
        slots += soon.sorted { $0.days < $1.days }
        var out: [HubAssignment] = []
        for (i, booking) in hubBookings.enumerated() where i < slots.count {
            let slot = slots[i]
            out.append(HubAssignment(id: booking.id, booking: booking, unitID: slot.unit, inDays: slot.days))
        }
        return out
    }

    /// PLACEHOLDER rule: swap top and bottom trays every 4 days of drying.
    static let traySwapEveryDays: Int = 4

    /// Today's jobs for the operator, derived from the yard.
    static var hubTasks: [HubTask] {
        var list: [HubTask] = []
        func add(_ symbol: String, _ key: String, _ args: [String: String]) {
            list.append(HubTask(id: list.count, symbol: symbol, key: key, args: args))
        }
        let p: CropProfile = Simulation.chilli
        for u in Simulation.hubUnits where u.mode == .drying {
            let left: Int = p.daysLeft(u.day)
            let day: Int = p.dayNumber(u.day)
            if left <= 1 {
                add("shippingbox.fill", "u_task_bag", ["id": "\(u.id)", "n": "\(bagsFor(kg: dryingLoadKg(u.id)))"])
            } else if day > 0 && day % traySwapEveryDays == 0 {
                add("arrow.up.arrow.down.circle.fill", "u_task_swap", ["id": "\(u.id)"])
            }
        }
        for a in hubAssignments where a.inDays == 0 {
            add("tray.and.arrow.down.fill", "u_task_load", ["id": "\(a.unitID)", "f": a.booking.farmer])
        }
        for u in Simulation.hubUnits where u.mode == .storing {
            let d: Int = storageDays(u.id)
            if d > 0 && d % 7 == 0 {
                add("humidity.fill", "u_task_check", ["id": "\(u.id)"])
            }
        }
        return list
    }

    /// Dried crop brought in from elsewhere only to be stored, if the yard holds more than
    /// it has dried this season (keeps the season figures consistent).
    static var hubStoredOnlyKg: Int {
        let stored: Int = Simulation.hubUnits.reduce(0) { $0 + $1.bags } * Simulation.kgPerBag
        return max(0, stored - Simulation.hubDriedKgThisSeason)
    }

    // MARK: - Selling

    /// PLACEHOLDER: hired small truck, ₹50 per 100 kg loading and unloading
    /// plus ₹2 per 100 kg per km (≈ ₹20 per tonne-km).
    static func freightPer100kg(distanceKm: Int) -> Int {
        50 + 2 * distanceKm
    }

    static func commissionPer100kg(price: Int) -> Int {
        price * Simulation.commissionPercent / 100
    }

    static func netPer100kg(price: Int, distanceKm: Int) -> Int {
        price - freightPer100kg(distanceKm: distanceKm) - commissionPer100kg(price: price)
    }

    /// PLACEHOLDER: 12% a year crop-loan interest, the cost of waiting for a better price.
    static let interestPercentPerYear: Double = 12

    static func waitingCost(worth: Int, days: Int) -> Int {
        let v: Double = Double(worth) * interestPercentPerYear / 100 * Double(days) / 365
        return Int(v.rounded())
    }
}
