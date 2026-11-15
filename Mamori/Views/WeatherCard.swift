import SwiftUI

/// Home weather, folded to one row: icon, verdict, rain chance, temperature.
/// Open: today's readings and verdict, the next 3 hours hour by hour, the rest of
/// today (Now / +3 / +6 / +9 h) and the next 3 days with a drying verdict per day.
/// When the "Rain in 40 min" demo fires, the whole card turns blue.
struct WeatherCard: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        let rain: Int? = store.rainMinutesLeft(at: store.now)
        let raining: Bool = rain != nil
        let fill: Color = raining ? Theme.weatherRainCard : Theme.surface
        let ink: Color = raining ? Theme.onDark : Theme.ink
        let muted: Color = raining ? Theme.onDark : Theme.inkStrong
        let rainAnimation: Animation? = Theme.motion(.easeInOut(duration: 0.5), reduce: reduceMotion)
        ExpandableCard(isExpanded: isExpanded, summary: spokenSummary(rain: rain),
                       fill: fill, ink: ink, onToggle: onToggle) {
            WeatherFoldedRow(raining: raining, ink: ink, muted: muted)
        } content: {
            WeatherDetail(rain: rain, ink: ink, muted: muted)
        }
        .animation(rainAnimation, value: raining)
    }

    private func spokenSummary(rain: Int?) -> String {
        var parts: [String] = [store.t("weather_today") + ", " + store.t("location_guntur")]
        let closed: String = store.homeClosedVentUnits
        if let rain {
            parts.append(store.t("rain_in", ["n": "\(rain)"]))
            parts.append(store.t("drying_bad"))
            if !closed.isEmpty { parts.append(store.t("rain_vents", ["u": closed])) }
        } else {
            parts.append(store.t("home_degrees", ["t": "\(Simulation.outsideTempC)"]))
            let verdict: DryingVerdict = Simulation.dryingVerdict(raining: false)
            parts.append(store.t(verdict == .good ? "good_drying" : "drying_watch"))
            parts.append(store.t("sun_left", ["h": "\(Simulation.sunHoursLeft)"]))
        }
        let rainNow: Int = Simulation.forecast(raining: rain != nil).first?.rainPercent ?? 0
        parts.append(store.t("rain_chance", ["p": "\(rainNow)"]))
        parts.append(store.t("feels_like", ["t": "\(Simulation.feelsLikeC)"]))
        parts.append(store.t("humidity_out") + " \(Simulation.outsideHumidity)%")
        parts.append(store.t("wind") + " \(Simulation.windKmh) km/h")
        return parts.joined(separator: ". ")
    }
}

// MARK: - Folded row

private struct WeatherFoldedRow: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let raining: Bool
    let ink: Color
    let muted: Color

    var body: some View {
        let verdict: DryingVerdict = Simulation.dryingVerdict(raining: raining)
        let symbol: String = raining ? "cloud.heavyrain.fill" : "sun.max.fill"
        let iconColor: Color = raining ? Theme.onDark : Theme.sun
        let titleKey: String = Self.verdictKey(verdict)
        let rainNow: Int = Simulation.forecast(raining: raining).first?.rainPercent ?? 0
        let subtitle: String = store.t("location_guntur") + " · " + store.t("rain_chance", ["p": "\(rainNow)"])
        let tempColor: Color = raining ? Theme.onDark : Theme.outsideTempColor(Simulation.outsideTempC)
        let pulse: Bool = raining && !reduceMotion
        HStack(alignment: .center, spacing: Theme.space3) {
            Image(systemName: symbol)
                .font(Theme.sectionTitle)
                .foregroundStyle(iconColor)
                .symbolEffect(.pulse, isActive: pulse)
                .frame(width: HomeStyle.iconWidth)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.t(titleKey))
                    .font(HomeStyle.rowTitle)
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(subtitle)
                    .font(Theme.small)
                    .foregroundStyle(muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Theme.space1)
            Text(verbatim: "\(Simulation.outsideTempC)°")
                .font(HomeStyle.rowNumber)
                .foregroundStyle(tempColor)
                .lineLimit(1)
                .fixedSize()
                .layoutPriority(1)
        }
    }

    static func verdictKey(_ verdict: DryingVerdict) -> String {
        switch verdict {
        case .good: return "home_wx_good"
        case .watch: return "home_wx_slow"
        case .bad: return "home_wx_cover"
        }
    }
}

// MARK: - Open card

private struct WeatherDetail: View {
    @Environment(AppStore.self) private var store
    let rain: Int?
    let ink: Color
    let muted: Color

    var body: some View {
        let raining: Bool = rain != nil
        VStack(alignment: .leading, spacing: Theme.spacing) {
            HomeSubheading(text: store.t("weather_today"), symbol: "location.fill", color: muted)
            WeatherNowBlock(rain: rain, ink: ink, muted: muted)
            HomeSubheading(text: store.t("home_next_hours"), symbol: "clock", color: muted)
            WeatherHoursRow(raining: raining)
            HomeSubheading(text: store.t("home_rest_today"), symbol: "sun.max", color: muted)
            WeatherTodayLine(raining: raining)
            HomeSubheading(text: store.t("home_next_days"), symbol: "calendar", color: muted)
            WeatherDaysList(raining: raining)
        }
    }
}

/// Today's readings: rain countdown or verdict, feels like, humidity, wind, sun left.
private struct WeatherNowBlock: View {
    @Environment(AppStore.self) private var store
    let rain: Int?
    let ink: Color
    let muted: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space2) {
            verdict
            readings
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var verdict: some View {
        if let rain {
            let closed: String = store.homeClosedVentUnits
            HStack(alignment: .firstTextBaseline, spacing: Theme.space2) {
                Text(verbatim: "\(rain) min")
                    .font(Theme.bigNumber)
                    .foregroundStyle(Theme.onDark)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Text(store.t("rain_in", ["n": "\(rain)"]))
                    .font(Theme.label)
                    .foregroundStyle(Theme.onDark)
                    .lineLimit(2)
            }
            Label(store.t("drying_bad"), systemImage: "exclamationmark.triangle.fill")
                .font(Theme.label)
                .foregroundStyle(Theme.onDark)
                .padding(.horizontal, Theme.space3)
                .padding(.vertical, Theme.space2)
                .background(Theme.statusDanger, in: Capsule())
            if !closed.isEmpty {
                Label(store.t("rain_vents", ["u": closed]), systemImage: "lock.fill")
                    .font(Theme.label)
                    .foregroundStyle(Theme.onDark)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            let v: DryingVerdict = Simulation.dryingVerdict(raining: false)
            let key: String = v == .good ? "good_drying" : "drying_watch"
            let color: Color = v == .good ? Theme.good : Theme.warn
            let symbol: String = v == .good ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
            Label(store.t(key), systemImage: symbol)
                .font(Theme.headline)
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
            Text(store.t("sun_left", ["h": "\(Simulation.sunHoursLeft)"]))
                .font(Theme.label)
                .foregroundStyle(muted)
        }
    }

    private var readings: some View {
        let raining: Bool = rain != nil
        let feelsColor: Color = raining ? ink : Theme.outsideTempColor(Simulation.feelsLikeC)
        let humidityColor: Color = raining ? ink : Theme.outsideHumidityColor(Simulation.outsideHumidity)
        let feels: String = store.t("feels_like", ["t": "\(Simulation.feelsLikeC)"])
        let humidity: String = store.t("humidity_out") + " \(Simulation.outsideHumidity)%"
        let wind: String = store.t("wind") + " \(Simulation.windKmh) km/h"
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.spacing) {
                reading(symbol: "thermometer.medium", text: feels, color: feelsColor)
                reading(symbol: "humidity.fill", text: humidity, color: humidityColor)
                reading(symbol: "wind", text: wind, color: ink)
            }
            VStack(alignment: .leading, spacing: Theme.space1) {
                reading(symbol: "thermometer.medium", text: feels, color: feelsColor)
                reading(symbol: "humidity.fill", text: humidity, color: humidityColor)
                reading(symbol: "wind", text: wind, color: ink)
            }
        }
    }

    private func reading(symbol: String, text: String, color: Color) -> some View {
        Label(text, systemImage: symbol)
            .font(Theme.label)
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
    }
}

/// Now, +1 h, +2 h, +3 h: temperature, rain chance, humidity.
private struct WeatherHoursRow: View {
    @Environment(AppStore.self) private var store
    let raining: Bool

    var body: some View {
        let hours: [HourForecast] = HomeSim.nextHours(raining: raining)
        HStack(spacing: Theme.space2) {
            ForEach(hours) { hour in
                hourTile(hour)
            }
        }
    }

    private func hourTile(_ hour: HourForecast) -> some View {
        let label: String = hour.id == 0 ? store.t("now") : "+\(hour.id) h"
        let wet: Bool = hour.rainPercent >= 30
        let symbol: String = wet ? "cloud.rain.fill" : "sun.max.fill"
        let iconColor: Color = wet ? Theme.rain : Theme.sun
        let rainText: String = "\(hour.rainPercent)%"
        let humidText: String = "\(hour.humidity)%"
        return VStack(spacing: 2) {
            Text(label)
                .font(Theme.small)
                .foregroundStyle(Theme.inkStrong)
                .minimumScaleFactor(0.8)
            Image(systemName: symbol)
                .font(Theme.label)
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)
            Text(verbatim: "\(hour.tempC)°")
                .font(Theme.headline)
                .foregroundStyle(Theme.outsideTempColor(hour.tempC))
            Label(rainText, systemImage: "drop.fill")
                .font(Theme.small)
                .foregroundStyle(Theme.rainChanceColor(hour.rainPercent))
            Label(humidText, systemImage: "humidity.fill")
                .font(Theme.small)
                .foregroundStyle(Theme.outsideHumidityColor(hour.humidity))
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.space2)
        .background(Theme.weatherSlot, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(hourSpoken(hour, label: label))
    }

    private func hourSpoken(_ hour: HourForecast, label: String) -> String {
        [label,
         store.t("home_degrees", ["t": "\(hour.tempC)"]),
         store.t("rain_chance", ["p": "\(hour.rainPercent)"]),
         store.t("humidity_out") + " \(hour.humidity)%"].joined(separator: ", ")
    }
}

/// The original Now / +3 / +6 / +9 h strip, as one compact line.
private struct WeatherTodayLine: View {
    @Environment(AppStore.self) private var store
    let raining: Bool

    var body: some View {
        let slots: [ForecastSlot] = Simulation.forecast(raining: raining)
        HStack(spacing: 0) {
            ForEach(slots) { slot in
                slotCell(slot)
            }
        }
        .padding(.vertical, Theme.space2)
        .background(Theme.weatherSlot, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
    }

    private func slotCell(_ slot: ForecastSlot) -> some View {
        let label: String = slot.id == 0 ? store.t("now") : "+\(slot.id) h"
        return VStack(spacing: 0) {
            Text(label)
                .font(Theme.small)
                .foregroundStyle(Theme.inkStrong)
                .minimumScaleFactor(0.8)
            Text(verbatim: "\(slot.tempC)°")
                .font(Theme.label)
                .foregroundStyle(Theme.outsideTempColor(slot.tempC))
            Text(verbatim: "\(slot.rainPercent)%")
                .font(Theme.small)
                .foregroundStyle(Theme.rainChanceColor(slot.rainPercent))
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label + ", " + store.t("home_degrees", ["t": "\(slot.tempC)"]) + ", "
                            + store.t("rain_chance", ["p": "\(slot.rainPercent)"]))
    }
}

/// Tomorrow and the two days after: day name, high/low, rain chance, drying verdict.
private struct WeatherDaysList: View {
    @Environment(AppStore.self) private var store
    let raining: Bool

    var body: some View {
        let days: [DayForecast] = HomeSim.nextDays(raining: raining)
        VStack(spacing: Theme.space2) {
            ForEach(days) { day in
                dayRow(day)
            }
        }
    }

    private func dayName(_ day: DayForecast) -> String {
        if day.id == 1 { return store.t("hub_queue_tomorrow") }
        let date: Date = HomeSim.date(daysAhead: day.id, from: store.now)
        let style: Date.FormatStyle = Date.FormatStyle().weekday(.wide).locale(L10n.locale(store.lang))
        return date.formatted(style)
    }

    private func verdictText(_ v: DayDryingVerdict) -> String {
        switch v {
        case .good: return store.t("home_day_good")
        case .slow: return store.t("home_day_slow")
        case .cover: return store.t("home_day_cover")
        }
    }

    private func verdictColor(_ v: DayDryingVerdict) -> Color {
        switch v {
        case .good: return Theme.good
        case .slow: return Theme.warn
        case .cover: return Theme.danger
        }
    }

    private func dayRow(_ day: DayForecast) -> some View {
        let name: String = dayName(day)
        let wet: Bool = day.rainPercent >= 30
        let symbol: String = wet ? "cloud.rain.fill" : "sun.max.fill"
        let iconColor: Color = wet ? Theme.rain : Theme.sun
        let verdict: String = verdictText(day.verdict)
        let vColor: Color = verdictColor(day.verdict)
        let highLow: String = "\(day.highC)° / \(day.lowC)°"
        let spoken: String = [name, highLow, store.t("rain_chance", ["p": "\(day.rainPercent)"]), verdict]
            .joined(separator: ", ")
        let rainText: String = store.t("rain_chance", ["p": "\(day.rainPercent)"])
        return HStack(spacing: Theme.space2) {
            Image(systemName: symbol)
                .font(Theme.headline)
                .foregroundStyle(iconColor)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(Theme.label)
                    .foregroundStyle(Theme.ink)
                HStack(spacing: Theme.space2) {
                    Text(verbatim: highLow)
                        .font(Theme.small)
                        .foregroundStyle(Theme.ink)
                    Text(rainText)
                        .font(Theme.small)
                        .foregroundStyle(Theme.rainChanceColor(day.rainPercent))
                }
            }
            .lineLimit(1)
            Spacer(minLength: Theme.space1)
            Text(verdict)
                .font(Theme.smallBold)
                .foregroundStyle(vColor)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, Theme.space3)
                .padding(.vertical, Theme.space1)
                .background(vColor.opacity(0.14), in: Capsule())
        }
        .padding(.vertical, Theme.space2)
        .padding(.horizontal, Theme.space3)
        .frame(minHeight: Theme.minTap)
        .background(Theme.weatherSlot, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }
}
