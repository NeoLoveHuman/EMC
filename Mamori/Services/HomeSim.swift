import Foundation

/// One hour of the Home weather card's "next 3 hours".
struct HourForecast: Identifiable {
    let id: Int               // hours from now (0 = now)
    let tempC: Int
    let rainPercent: Int
    let humidity: Int
}

/// Is a coming day good for drying?
enum DayDryingVerdict { case good, slow, cover }

/// One day of the Home weather card's "next 3 days".
struct DayForecast: Identifiable {
    let id: Int               // days from today (1 = tomorrow)
    let highC: Int
    let lowC: Int
    let rainPercent: Int
    let humidity: Int

    var verdict: DayDryingVerdict { HomeSim.verdict(rainPercent: rainPercent, humidity: humidity) }
}

/// Extra, invented forecast for the expandable weather card on Home. App target only.
/// "Now" and "+3 h" come straight from Simulation (31 °C, 58%, forecast slots), so the
/// numbers never disagree with the rest of the app. Everything else is a PLACEHOLDER.
enum HomeSim {

    /// Now, +1 h, +2 h, +3 h. When the rain scene is on, the next hours show rain.
    static func nextHours(raining: Bool) -> [HourForecast] {
        let slots: [ForecastSlot] = Simulation.forecast(raining: raining)
        let nowRain: Int = slots.first { $0.id == 0 }?.rainPercent ?? (raining ? 90 : 5)
        let in3Temp: Int = slots.first { $0.id == 3 }?.tempC ?? (raining ? 27 : 32)
        let in3Rain: Int = slots.first { $0.id == 3 }?.rainPercent ?? (raining ? 60 : 10)
        let now = HourForecast(id: 0, tempC: Simulation.outsideTempC, rainPercent: nowRain,
                               humidity: Simulation.outsideHumidity)
        if raining {
            return [
                now,
                HourForecast(id: 1, tempC: 27, rainPercent: 95, humidity: 88),       // PLACEHOLDER
                HourForecast(id: 2, tempC: 26, rainPercent: 80, humidity: 90),       // PLACEHOLDER
                HourForecast(id: 3, tempC: in3Temp, rainPercent: in3Rain, humidity: 85)  // PLACEHOLDER humidity
            ]
        }
        return [
            now,
            HourForecast(id: 1, tempC: 32, rainPercent: 5, humidity: 55),            // PLACEHOLDER
            HourForecast(id: 2, tempC: 32, rainPercent: 10, humidity: 54),           // PLACEHOLDER
            HourForecast(id: 3, tempC: in3Temp, rainPercent: in3Rain, humidity: 55)  // PLACEHOLDER humidity
        ]
    }

    /// Tomorrow and the two days after.
    /// Dry scene: two drying days, then rain on day 3 (Unit A is dry before it arrives).
    /// Rain scene: a damp day tomorrow, then it clears.
    static func nextDays(raining: Bool) -> [DayForecast] {
        if raining {
            return [
                DayForecast(id: 1, highC: 29, lowC: 23, rainPercent: 40, humidity: 75),   // PLACEHOLDER
                DayForecast(id: 2, highC: 31, lowC: 24, rainPercent: 15, humidity: 62),   // PLACEHOLDER
                DayForecast(id: 3, highC: 32, lowC: 24, rainPercent: 10, humidity: 58)    // PLACEHOLDER
            ]
        }
        return [
            DayForecast(id: 1, highC: 33, lowC: 24, rainPercent: 10, humidity: 55),       // PLACEHOLDER
            DayForecast(id: 2, highC: 32, lowC: 24, rainPercent: 35, humidity: 68),       // PLACEHOLDER
            DayForecast(id: 3, highC: 30, lowC: 23, rainPercent: 65, humidity: 82)        // PLACEHOLDER
        ]
    }

    /// PLACEHOLDER rule: likely rain = cover, some rain or humid air = slow, else good.
    static func verdict(rainPercent: Int, humidity: Int) -> DayDryingVerdict {
        if rainPercent >= 60 { return .cover }
        if rainPercent >= 30 || humidity > 70 { return .slow }
        return .good
    }

    /// The calendar date `days` after `now` (never fails).
    static func date(daysAhead days: Int, from now: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: now)
            ?? now.addingTimeInterval(Double(days) * Simulation.secondsPerDay)
    }
}
