import SwiftUI

/// Home: today's weather, colour-coded (green fine, amber watch, red bad),
/// with a one-line drying verdict and the next 9 hours.
/// When the "Rain in 40 min" demo fires, the whole card turns blue with a countdown.
struct WeatherCard: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let rain: Int? = store.rainMinutesLeft(at: store.now)
        let raining: Bool = rain != nil
        let ink: Color = raining ? Theme.onDark : Theme.ink
        let muted: Color = raining ? Theme.onDark : Theme.inkStrong
        let pulse: Bool = raining && !reduceMotion
        let cardFill: Color = raining ? Theme.weatherRainCard : Theme.surface

        VStack(alignment: .leading, spacing: Theme.spacing) {
            // Title row
            HStack {
                MamoriCardTitle(text: store.t("weather_today"), symbol: "location.fill", color: muted)
                Spacer(minLength: Theme.space2)
                Text(store.t("location_guntur"))
                    .font(Theme.label)
                    .foregroundStyle(muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            readingRow(rain: rain, ink: ink, pulse: pulse)

            verdictRow(raining: raining)

            // Next 9 hours
            HStack(spacing: Theme.space2) {
                ForEach(Simulation.forecast(raining: raining)) { slot in
                    slotView(slot)
                }
            }
        }
        .card(fill: cardFill)
        .animation(Theme.motion(.easeInOut(duration: 0.5), reduce: reduceMotion), value: raining)
        .animation(Theme.motion(Theme.motionQuick, reduce: reduceMotion), value: rain)
        // One full sentence for VoiceOver instead of a dozen fragments.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenSummary(rain: rain))
    }

    /// Big reading (temperature, or the rain countdown) with the details column.
    private func readingRow(rain: Int?, ink: Color, pulse: Bool) -> some View {
        let raining: Bool = rain != nil
        let symbol: String = raining ? "cloud.heavyrain.fill" : "sun.max.fill"
        let iconColor: Color = raining ? Theme.onDark : Theme.sun
        let feelsColor: Color = raining ? ink : Theme.outsideTempColor(Simulation.feelsLikeC)
        let humidityColor: Color = raining ? ink : Theme.outsideHumidityColor(Simulation.outsideHumidity)
        let feelsText: String = store.t("feels_like", ["t": "\(Simulation.feelsLikeC)"])
        let humidityText: String = store.t("humidity_out") + " \(Simulation.outsideHumidity)%"
        let windText: String = store.t("wind") + " \(Simulation.windKmh) km/h"
        return HStack(alignment: .center, spacing: Theme.spacing) {
            Image(systemName: symbol)
                .font(Theme.weatherIcon)
                .foregroundStyle(iconColor)
                .symbolEffect(.pulse, isActive: pulse)
                .accessibilityHidden(true)
            bigReading(rain: rain)
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: Theme.space2) {
                detail(symbol: "thermometer.medium", text: feelsText, color: feelsColor)
                detail(symbol: "humidity.fill", text: humidityText, color: humidityColor)
                detail(symbol: "wind", text: windText, color: ink)
            }
        }
    }

    @ViewBuilder
    private func bigReading(rain: Int?) -> some View {
        if let rain {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: "\(rain) min")
                    .font(Theme.weatherTemp)
                    .foregroundStyle(Theme.onDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
                Text(store.t("rain_in", ["n": "\(rain)"]))
                    .font(Theme.headline)
                    .foregroundStyle(Theme.onDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .layoutPriority(1)
        } else {
            Text(verbatim: "\(Simulation.outsideTempC)°")
                .font(Theme.weatherTemp)
                .foregroundStyle(Theme.outsideTempColor(Simulation.outsideTempC))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
                .layoutPriority(1)
        }
    }

    private func spokenSummary(rain: Int?) -> String {
        var parts: [String] = [store.t("weather_today") + ", " + store.t("location_guntur")]
        if let rain {
            parts.append(store.t("rain_in", ["n": "\(rain)"]))
            parts.append(store.t("drying_bad"))
            if !closedUnits.isEmpty { parts.append(store.t("rain_vents", ["u": closedUnits])) }
        } else {
            parts.append(store.t("home_degrees", ["t": "\(Simulation.outsideTempC)"]))
            let verdict: DryingVerdict = Simulation.dryingVerdict(raining: false)
            parts.append(store.t(verdict == .good ? "good_drying" : "drying_watch"))
            parts.append(store.t("sun_left", ["h": "\(Simulation.sunHoursLeft)"]))
        }
        parts.append(store.t("feels_like", ["t": "\(Simulation.feelsLikeC)"]))
        parts.append(store.t("humidity_out") + " \(Simulation.outsideHumidity)%")
        parts.append(store.t("wind") + " \(Simulation.windKmh) km/h")
        return parts.joined(separator: ". ")
    }

    private func detail(symbol: String, text: String, color: Color) -> some View {
        Label(text, systemImage: symbol)
            .font(Theme.label)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    /// "Good drying weather" / "Humid air: drying slower" / "Rain coming: vents shut".
    @ViewBuilder
    private func verdictRow(raining: Bool) -> some View {
        let verdict: DryingVerdict = Simulation.dryingVerdict(raining: raining)
        if raining {
            VStack(alignment: .leading, spacing: Theme.space2) {
                Label(store.t("drying_bad"), systemImage: "exclamationmark.triangle.fill")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.onDark)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, Theme.space3)
                    .padding(.vertical, Theme.space2)
                    .background(Theme.statusDanger, in: Capsule())
                if !closedUnits.isEmpty {
                    Label(store.t("rain_vents", ["u": closedUnits]), systemImage: "lock.fill")
                        .font(Theme.label)
                        .foregroundStyle(Theme.onDark)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
            }
        } else {
            let key: String = verdict == .good ? "good_drying" : "drying_watch"
            let color: Color = verdict == .good ? Theme.good : Theme.warn
            let symbol: String = verdict == .good ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
            // Wraps to two lines rather than shrinking: Telugu and Hindi verdicts run long.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.space2) {
                    verdictLabel(key: key, symbol: symbol, color: color)
                    Spacer(minLength: Theme.space1)
                    sunLeftLabel
                }
                VStack(alignment: .leading, spacing: Theme.space1) {
                    verdictLabel(key: key, symbol: symbol, color: color)
                    sunLeftLabel
                }
            }
        }
    }

    private func verdictLabel(key: String, symbol: String, color: Color) -> some View {
        Label(store.t(key), systemImage: symbol)
            .font(Theme.headline)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private var sunLeftLabel: some View {
        Text(store.t("sun_left", ["h": "\(Simulation.sunHoursLeft)"]))
            .font(Theme.label)
            .foregroundStyle(Theme.inkStrong)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    /// Drying units whose vents are shut, e.g. "A, C".
    private var closedUnits: String {
        store.state.units
            .filter { $0.mode == .drying && $0.vent == .closed }
            .map { $0.id }
            .joined(separator: ", ")
    }

    private func slotView(_ slot: ForecastSlot) -> some View {
        let label: String = slot.id == 0 ? store.t("now") : "+\(slot.id) h"
        let wet: Bool = slot.rainPercent >= 30
        return VStack(spacing: Theme.space1) {
            Text(label)
                .font(Theme.small)
                .foregroundStyle(Theme.inkStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Image(systemName: wet ? "cloud.rain.fill" : "sun.max.fill")
                .font(Theme.headline)
                .foregroundStyle(wet ? Theme.rain : Theme.sun)
                .accessibilityHidden(true)
            Text(verbatim: "\(slot.tempC)°")
                .font(Theme.headline)
                .foregroundStyle(Theme.outsideTempColor(slot.tempC))
            Text(verbatim: "\(slot.rainPercent)%")
                .font(Theme.label)
                .foregroundStyle(Theme.rainChanceColor(slot.rainPercent))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.space2)
        .background(Theme.weatherSlot, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
        .accessibilityElement(children: .combine)
    }
}
