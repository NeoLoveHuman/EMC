import SwiftUI

/// The Units tab. "My farm": one card per unit (A, B, C ...), tap for the batch detail.
/// "Hub": the operator's view of a 20-unit yard.
struct HomeView: View {
    @Environment(AppStore.self) private var store
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacing) {
                    header
                    SegmentSwitch(titles: [store.t("my_farm"), store.t("hub")],
                                  symbols: ["house.fill", "square.grid.3x3.fill"],
                                  index: sideBinding)
                    if !store.unitsShowHub {
                        weatherStrip
                        ForEach(store.state.units) { unit in
                            NavigationLink(value: unit.id) {
                                UnitCard(unit: unit)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        HubView()
                    }
                }
                .padding(Theme.padding)
                .padding(.bottom, Theme.scrollBottomInset)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { id in
                BatchDetailView(unitID: id)
            }
            .mamoriToolbar()
        }
        .onAppear { consumeDeepLink() }
        .onChange(of: store.deepLinkUnitID) { consumeDeepLink() }
    }

    // Hidden: triple-tap the title to open the demo panel.
    private var header: some View {
        HStack {
            Text(store.t("my_units"))
                .font(Theme.screenTitle)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 3) { store.showDemoPanel = true }
    }

    /// 0 = my farm, 1 = hub. Kept in the store so the voice assistant knows which one is open.
    private var sideBinding: Binding<Int> {
        Binding(get: { store.unitsShowHub ? 1 : 0 },
                set: { store.unitsShowHub = $0 == 1 })
    }

    private var weatherStrip: some View {
        let temp: String = String(Simulation.outsideTempC) + "°"
        let humidity: String = String(Simulation.outsideHumidity) + "%"
        let rainText: String? = store.rainMinutesLeft(at: store.now).map { store.t("rain_in", ["n": "\($0)"]) }
        let skyText: String = rainText ?? store.t("no_rain")
        let spoken: String = [store.t("home_degrees", ["t": String(Simulation.outsideTempC)]),
                              store.t("humidity_out") + " " + humidity,
                              skyText].joined(separator: ", ")
        return HStack(spacing: Theme.space3) {
            Label(temp, systemImage: "thermometer.sun.fill")
                .foregroundStyle(Theme.outsideTempColor(Simulation.outsideTempC))
            Label(humidity, systemImage: "humidity.fill")
                .foregroundStyle(Theme.outsideHumidityColor(Simulation.outsideHumidity))
            Spacer(minLength: 0)
            if let rainText {
                Label(rainText, systemImage: "cloud.rain.fill")
                    .foregroundStyle(Theme.onDark)
                    .padding(.horizontal, Theme.space3)
                    .padding(.vertical, 6)
                    .background(Theme.rain, in: Capsule())
            } else {
                Label(skyText, systemImage: "sun.max.fill")
            }
        }
        .font(Theme.label)
        .foregroundStyle(Theme.ink)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private func consumeDeepLink() {
        guard let id = store.deepLinkUnitID else { return }
        store.deepLinkUnitID = nil
        store.unitsShowHub = false
        path = [id]
    }
}
