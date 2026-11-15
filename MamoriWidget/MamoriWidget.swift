import WidgetKit
import SwiftUI

// MARK: - Timeline

struct MamoriEntry: TimelineEntry {
    let date: Date
    let state: SharedState
}

struct MamoriProvider: TimelineProvider {

    /// Reads the app's state from the App Group. If the App Group is not
    /// provisioned, nothing is found and the seed state is used: the widget
    /// then always shows "day 12" (spec section 6 fallback).
    private func currentState() -> SharedState {
        SharedStore.load() ?? .seed()
    }

    func placeholder(in context: Context) -> MamoriEntry {
        MamoriEntry(date: Date(), state: .seed())
    }

    func getSnapshot(in context: Context, completion: @escaping (MamoriEntry) -> Void) {
        completion(MamoriEntry(date: Date(), state: currentState()))
    }

    /// One entry every 15 minutes for the next 6 hours, same Simulation as the app.
    func getTimeline(in context: Context, completion: @escaping (Timeline<MamoriEntry>) -> Void) {
        let state = currentState()
        let start = Date()
        let entries = (0..<24).map { i in
            MamoriEntry(date: start.addingTimeInterval(Double(i) * 15 * 60), state: state)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Views

struct MamoriWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MamoriEntry

    private var lang: String { entry.state.language }
    private func t(_ key: String, _ args: [String: String] = [:]) -> String { L10n.t(key, lang, args) }

    private var unit: Unit { entry.state.unit("A") ?? SharedState.seedUnitA() }
    private var day: Double { Simulation.day(since: unit.batchStart, at: entry.date) }
    private var moisture: Double { Simulation.moisture(of: unit, at: entry.date) }

    private var dayText: String {
        Simulation.isDry(day) ? t("ready") : t("day_of", ["d": "\(Simulation.dayNumber(day))", "t": "\(Int(Simulation.unitDryingDays))"])
    }

    // The widget shows the target vent state, so after "Rain" it reads "closed" at once.
    private var ventsOpen: Bool { unit.vent == .open }
    private var ventText: String { t(ventsOpen ? "vent_open" : "vent_closed") }

    /// Rain countdown at this entry's time (40, 25, 10, then 1), nil = no rain.
    private var rainMinutes: Int? { entry.state.rainMinutesLeft(at: entry.date) }
    private var raining: Bool { rainMinutes != nil }

    private var statusLine: String {
        if let mins = rainMinutes { return t("widget_rain", ["n": "\(mins)"]) }
        if entry.state.advice == .sell { return t("widget_sell") }
        let left = Simulation.daysLeft(day)
        return left >= 2 ? t("widget_hold", ["d": "\(left)"]) : t("widget_hold_soon")
    }

    var body: some View {
        content
            .containerBackground(for: .widget) {
                family == .accessoryRectangular ? Theme.clear : Theme.background
            }
            .widgetURL(URL(string: "mamori://unit/A"))
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryRectangular: lockScreen
        case .systemMedium: medium
        default: small
        }
    }

    // Small: crop, ring with %, "Day 12 of 14", vent status
    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                MoistureRing(moisture: moisture,
                             size: 68,
                             lineWidth: Theme.widgetRingLineWidth,
                             showTargetMarker: false,
                             numberFont: Theme.widgetNumber)
                VStack(alignment: .leading, spacing: 2) {
                    Text(t(unit.crop))
                        .font(Theme.widgetTitle)
                        .foregroundStyle(Theme.ink)
                    Text(t("unit", ["id": unit.id]))
                        .font(Theme.widgetCaption)
                        .foregroundStyle(Theme.inkMuted)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
            Text(dayText)
                .font(Theme.widgetBody)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            HStack(spacing: 4) {
                Image(systemName: ventsOpen ? "wind" : "lock.fill")
                Text(ventText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .font(Theme.widgetCaption)
            .foregroundStyle(ventsOpen ? Theme.onAccent : Theme.onDark)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(ventsOpen ? Theme.accent : Theme.ink, in: Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    // Medium: small content left; price and one status line right
    private var medium: some View {
        HStack(spacing: 12) {
            small
            Rectangle()
                .fill(Theme.ringTrack)
                .frame(width: 1)
            VStack(alignment: .leading, spacing: 4) {
                Text(t("widget_market"))
                    .font(Theme.widgetCaption)
                    .foregroundStyle(Theme.inkMuted)
                Text(Fmt.rupees(entry.state.pricePer100kg))
                    .font(Theme.widgetPrice)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(t("per_100kg") + " · " + Fmt.signedPercent(entry.state.priceChangePercent) + "%")
                    .font(Theme.widgetCaption)
                    .foregroundStyle(Theme.good)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 2)
                Text(statusLine)
                    .font(Theme.widgetBody)
                    .foregroundStyle(raining ? Theme.rain : Theme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    // Lock screen: "Chilli 11.8% · Vents open"
    private var lockScreen: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: "Mamori 守り")
                .font(Theme.lockTitle)
                .widgetAccentable()
            Text(t(unit.crop) + " " + Fmt.percent1(moisture) + " · " + ventText)
                .font(Theme.lockBody)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(raining ? statusLine : dayText)
                .font(Theme.lockCaption)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Widget

struct MamoriWidget: Widget {
    let kind: String = "MamoriWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MamoriProvider()) { entry in
            MamoriWidgetView(entry: entry)
        }
        .configurationDisplayName("Mamori")
        .description("Unit A: moisture, vents and market price.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
