import SwiftUI

/// First screen: the whole farm as a stack of small folded cards.
/// Tap a card to open it in place; opening one closes the other.
/// Collapsed, everything fits on one 6.1" screen without scrolling.
struct DashboardView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The one open card (nil = all folded).
    @State private var openSection: HomeSection? = nil
    @State private var didSetInitialSection: Bool = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    cards(proxy: proxy)
                }
                .background(Theme.background)
            }
            .navigationBarTitleDisplayMode(.inline)
            .mamoriToolbar()
        }
        .onAppear(perform: setInitialSection)
        .onChange(of: store.homeStatusLevel) { _, newLevel in
            statusLevelChanged(newLevel)
        }
    }

    private func cards(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: Theme.space3) {
            header
            HomeStatusCard(isExpanded: isOpen(.status),
                           onToggle: { toggle(.status, proxy: proxy) })
                .id(HomeSection.status)
            WeatherCard(isExpanded: isOpen(.weather),
                        onToggle: { toggle(.weather, proxy: proxy) })
                .id(HomeSection.weather)
            HomeUnitsCard(isExpanded: isOpen(.units),
                          onToggle: { toggle(.units, proxy: proxy) })
                .id(HomeSection.units)
            HomePriceCard(isExpanded: isOpen(.price),
                          onToggle: { toggle(.price, proxy: proxy) })
                .id(HomeSection.price)
            HomeFieldCard(isExpanded: isOpen(.field),
                          onToggle: { toggle(.field, proxy: proxy) })
                .id(HomeSection.field)
        }
        .padding(Theme.padding)
        .padding(.bottom, Theme.scrollBottomInset)
    }

    // MARK: Open / close

    private func isOpen(_ section: HomeSection) -> Bool {
        openSection == section
    }

    /// Opens `section` (closing any other) or closes it. A card opened lower down
    /// scrolls to the top so its detail is on screen.
    private func toggle(_ section: HomeSection, proxy: ScrollViewProxy) {
        let opening: Bool = openSection != section
        let animation: Animation? = HomeStyle.spring(reduce: reduceMotion)
        withAnimation(animation) {
            openSection = opening ? section : nil
        }
        guard opening, section != .status else { return }
        withAnimation(animation) {
            proxy.scrollTo(section, anchor: .top)
        }
    }

    /// Launch: all folded, unless rain is coming or the advice is SELL.
    private func setInitialSection() {
        guard !didSetInitialSection else { return }
        didSetInitialSection = true
        if store.homeStatusLevel != .safe {
            openSection = .status
        }
    }

    /// Rain or SELL fires (demo panel): open the status card. Reset demo: fold it again.
    private func statusLevelChanged(_ level: HomeStatusLevel) {
        let animation: Animation? = HomeStyle.spring(reduce: reduceMotion)
        withAnimation(animation) {
            if level != .safe {
                openSection = .status
            } else if openSection == .status {
                openSection = nil
            }
        }
    }

    // MARK: Header (hidden: triple-tap opens the demo panel)

    private var header: some View {
        HStack(alignment: .center, spacing: Theme.space3) {
            Image("MamoriLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: Theme.space3))
                .accessibilityHidden(true)
            Text(verbatim: "Mamori")
                .font(Theme.screenTitle)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Text(verbatim: "守り")
                .font(Theme.screenTitle)
                .foregroundStyle(Theme.inkMuted)
                .accessibilityHidden(true)
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 3) { store.showDemoPanel = true }
    }
}

// MARK: - Why: the facts behind the advice

struct ReasonList: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let warning: String? = rainReason
        VStack(alignment: .leading, spacing: 6) {
            Text(store.t("why"))
                .font(Theme.small)
                .foregroundStyle(Theme.inkStrong)
            ForEach(store.adviceReasons, id: \.self) { reason in
                row(reason, isWarning: reason == warning)
            }
        }
    }

    /// The rain line gets a red warning icon, not a green tick.
    private var rainReason: String? {
        guard let mins = store.rainMinutesLeft(at: store.now) else { return nil }
        return store.t("rain_in", ["n": "\(mins)"])
    }

    private func row(_ reason: String, isWarning: Bool) -> some View {
        let symbol: String = isWarning ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
        let tint: Color = isWarning ? Theme.danger : Theme.good
        return HStack(alignment: .firstTextBaseline, spacing: Theme.space2) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(reason)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(Theme.dynLabel)
    }
}

// MARK: - Mamori Eye: one field card (add-on)

/// Full field card (title + add-on badge + detail). Home now shows `FieldDetail`
/// inside a folding card; this stays for any other screen that wants the whole card.
struct FieldCard: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space2) {
            HStack {
                MamoriCardTitle(text: store.t("field_view"), symbol: "dot.radiowaves.left.and.right")
                Spacer(minLength: Theme.space2)
                Text(store.t("addon"))
                    .font(Theme.small)
                    .foregroundStyle(Theme.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.ink, in: Capsule())
            }
            FieldDetail()
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}

/// Field efficiency, the missed edge and soil moisture at three depths.
struct FieldDetail: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space2) {
            Text(store.t("field_eff", ["p": "\(Simulation.fieldEfficiencyPercent)"]))
                .font(Theme.dynHeadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Label(store.t("field_missed"), systemImage: "exclamationmark.triangle.fill")
                .font(Theme.dynLabel)
                .foregroundStyle(Theme.warn)
                .fixedSize(horizontal: false, vertical: true)
            Divider()
            soilRow
        }
        .accessibilityElement(children: .combine)
    }

    private var soilRow: some View {
        HStack(spacing: Theme.spacing) {
            Text(store.t("soil_moisture"))
                .font(Theme.label)
                .foregroundStyle(Theme.inkStrong)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            ForEach(Simulation.soilMoisture, id: \.depthCm) { reading in
                VStack(spacing: 2) {
                    Text(verbatim: "\(reading.percent)%")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.ink)
                    Text(verbatim: "\(reading.depthCm) cm")
                        .font(Theme.small)
                        .foregroundStyle(Theme.inkStrong)
                }
                .lineLimit(1)
            }
        }
    }
}

// MARK: - Pieces

struct ProgressRing: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let ringAnimation: Animation? = Theme.motion(.easeInOut(duration: 0.6), reduce: reduceMotion)
        ZStack {
            Circle()
                .stroke(Theme.ringTrack, lineWidth: lineWidth)
            if progress > 0 {
                Circle()
                    .trim(from: 0, to: min(1, progress))
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(lineWidth / 2)
        .animation(ringAnimation, value: progress)
    }
}

struct StatCircle: View {
    let symbol: String
    let value: String
    let caption: String
    let fill: Color
    let foreground: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(fill)
                VStack(spacing: 2) {
                    Image(systemName: symbol)
                        .font(Theme.headline)
                    Text(value)
                        .font(Theme.sectionTitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .contentTransition(.numericText())
                }
                .foregroundStyle(foreground)
                .padding(14)
            }
            .frame(width: 100, height: 100)
            Text(caption)
                .font(Theme.small)
                .foregroundStyle(Theme.inkStrong)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value + ", " + caption)
    }
}
