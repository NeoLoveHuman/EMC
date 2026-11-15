import SwiftUI
import Charts

/// Sell side of the Network tab (content only; NetworkView provides the scroll view).
struct SellView: View {
    @Environment(AppStore.self) private var store
    @State private var draftTarget = Simulation.defaultPriceAlert

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            priceCard
            adviceCard
            alertCard
            worthCard
            holdCard
            marketsCard
            trendCard
        }
    }

    // MARK: Price

    private var priceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.t("market_today"))
                .font(Theme.label)
                .foregroundStyle(Theme.inkMuted)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(Fmt.rupees(store.state.pricePer100kg))
                    .font(Theme.heroNumber)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
                Text(store.t("per_100kg"))
                    .font(Theme.headline)
                    .foregroundStyle(Theme.inkMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Text(store.t("vs_last_week", ["p": Fmt.signedPercent(store.state.priceChangePercent)]))
                .font(Theme.headline)
                .foregroundStyle(Theme.onDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Theme.good, in: Capsule())
        }
        .card()
    }

    // MARK: Advice

    private var adviceCard: some View {
        let isSell = store.state.advice == .sell
        return VStack(alignment: .leading, spacing: 12) {
            Text(store.t(isSell ? "sell" : "hold"))
                .font(Theme.bigNumber)
                .foregroundStyle(isSell ? Theme.onAccent : Theme.onDark)
                .padding(.horizontal, 18)
                .padding(.vertical, 6)
                .background(isSell ? Theme.accent : Theme.ink,
                            in: RoundedRectangle(cornerRadius: Theme.tileRadius))
            Text(store.adviceSentence)
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            ReasonList()
        }
        .card()
        .animation(.easeInOut, value: isSell)
    }

    // MARK: Price alert ("notify me at ₹16,000")

    private var alertCard: some View {
        let target = store.state.priceAlertTarget
        return VStack(alignment: .leading, spacing: 12) {
            Label(store.t("price_alert"), systemImage: "bell.badge.fill")
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)

            if let target {
                alertConfirmation(target: target)
            } else {
                HStack(spacing: 14) {
                    stepButton("minus", delta: -100)
                    Text(Fmt.rupees(draftTarget))
                        .font(Theme.bigNumber)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity)
                        .contentTransition(.numericText())
                    stepButton("plus", delta: 100)
                }
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { store.setPriceAlert(draftTarget) }
                } label: {
                    Text(store.t("notify_at", ["v": Fmt.rupees(draftTarget)]))
                        .font(Theme.headline)
                        .foregroundStyle(Theme.onAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
                }
                .buttonStyle(.plain)
            }
        }
        .card()
        .sensoryFeedback(.success, trigger: target)
    }

    /// Shown once the alert is set: a clear confirmation, how far the price has to go, and Remove.
    private func alertConfirmation(target: Int) -> some View {
        let price: Int = store.state.pricePer100kg
        let reached: Bool = price >= target
        let symbol: String = reached ? "checkmark.circle.fill" : "bell.fill"
        let fill: Color = reached ? Theme.good : Theme.ink
        let title: String = store.t(reached ? "alert_reached" : "alert_set", ["v": Fmt.rupees(target)])
        let note: String = reached ? store.t("u_alert_done") : store.t("u_alert_confirm")
        let gap: String = store.t("u_alert_gap", ["v": Fmt.rupees(max(0, target - price)), "p": Fmt.rupees(price)])
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbol)
                    .font(Theme.sectionTitle)
                    .foregroundStyle(Theme.onDark)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.onDark)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(note)
                        .font(Theme.label)
                        .foregroundStyle(Theme.onDark)
                        .fixedSize(horizontal: false, vertical: true)
                    if !reached {
                        Text(gap)
                            .font(Theme.label)
                            .foregroundStyle(Theme.onDark)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
            .accessibilityElement(children: .combine)
            .transition(.scale(scale: 0.9).combined(with: .opacity))

            Button {
                withAnimation(.easeInOut(duration: 0.3)) { store.setPriceAlert(nil) }
            } label: {
                Text(store.t("remove"))
                    .font(Theme.label)
                    .foregroundStyle(Theme.inkMuted)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func stepButton(_ symbol: String, delta: Int) -> some View {
        let sign: String = delta > 0 ? "+" : "−"
        let spoken: String = sign + Fmt.rupees(abs(delta))
        return Button {
            let range = Simulation.priceAlertRange
            withAnimation { draftTarget = min(range.upperBound, max(range.lowerBound, draftTarget + delta)) }
        } label: {
            Image(systemName: symbol)
                .font(Theme.headline)
                .foregroundStyle(Theme.onDark)
                .frame(width: 48, height: 48)
                .background(Theme.ink, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(spoken)
    }

    // MARK: Worth

    private var worthCard: some View {
        let kg = store.unitA.weightKg
        let worth = kg * store.state.pricePer100kg / 100
        let undried = kg * Simulation.harvestPricePer100kg / 100
        let sent = store.offerSent
        return VStack(alignment: .leading, spacing: 8) {
            Text(store.t("worth"))
                .font(Theme.headline)
                .foregroundStyle(Theme.ink)
            Text(Fmt.rupees(worth))
                .font(Theme.heroNumber)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
            Divider()
            Text(store.t("undried", ["v": Fmt.rupees(undried)]))
                .font(Theme.headline)
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
            // Poster: sell through the buyer network, 1% commission.
            Button {
                withAnimation { store.offerSent = true }
            } label: {
                VStack(spacing: 2) {
                    Text(store.t(sent ? "offer_sent" : "sell_via"))
                        .font(Theme.headline)
                    Text(store.t("commission", ["v": Fmt.rupees(worth * Simulation.commissionPercent / 100)]))
                        .font(Theme.caption)
                }
                .foregroundStyle(sent ? Theme.onDark : Theme.onAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(sent ? Theme.good : Theme.accent, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
            }
            .buttonStyle(.plain)
            .disabled(sent)
        }
        .card()
    }

    // MARK: Nearby markets: price, distance, transport, 1% fee and NET per 100 kg

    private func price(of market: Market) -> Int {
        market.fixedPrice ?? store.state.pricePer100kg
    }

    private func net(of market: Market) -> Int {
        UnitSim.netPer100kg(price: price(of: market), distanceKm: market.distanceKm)
    }

    private var bestMarketID: String? {
        Simulation.markets.max { net(of: $0) < net(of: $1) }?.id
    }

    private var marketsCard: some View {
        let best: String? = bestMarketID
        return VStack(alignment: .leading, spacing: 0) {
            Text(store.t("nearby_markets"))
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
            Text(store.t("u_net_note"))
                .font(Theme.caption)
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 6)
            ForEach(Simulation.markets) { market in
                marketRow(market, isBest: market.id == best)
                if market.id != Simulation.markets.last?.id { Divider() }
            }
        }
        .card()
    }

    private func marketRow(_ market: Market, isBest: Bool) -> some View {
        let p: Int = price(of: market)
        let expected: Int = max(market.expectedNextWeek, market.fixedPrice == nil ? store.state.pricePer100kg : 0)
        let freight: Int = UnitSim.freightPer100kg(distanceKm: market.distanceKm)
        let fee: Int = UnitSim.commissionPer100kg(price: p)
        let netValue: Int = net(of: market)
        let costs: String = store.t("u_transport", ["v": Fmt.rupees(freight)]) + " · " + store.t("u_fee1", ["v": Fmt.rupees(fee)])
        let netText: String = store.t("u_net", ["v": Fmt.rupees(netValue)])
        let netFill: Color = isBest ? Theme.accent : Theme.background
        var spoken: [String] = [store.t(market.nameKey), store.t("km", ["n": "\(market.distanceKm)"]),
                                Fmt.rupees(p) + " " + store.t("per_100kg"), costs, netText,
                                store.t("expected_next_week", ["v": Fmt.rupees(expected)])]
        if isBest { spoken.insert(store.t("u_best_net"), at: 0) }

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.t(market.nameKey))
                        .font(Theme.headline)
                        .foregroundStyle(Theme.ink)
                    Text(store.t("km", ["n": "\(market.distanceKm)"]))
                        .font(Theme.caption)
                        .foregroundStyle(Theme.inkMuted)
                }
                Spacer(minLength: 8)
                Text(Fmt.rupees(p))
                    .font(Theme.sectionTitle)
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
            }
            Text(costs)
                .font(Theme.label)
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Text(netText)
                    .font(Theme.headline)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(netFill, in: Capsule())
                    .contentTransition(.numericText())
                if isBest {
                    Label(store.t("u_best_net"), systemImage: "star.fill")
                        .font(Theme.label)
                        .foregroundStyle(Theme.good)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            Text(store.t("expected_next_week", ["v": Fmt.rupees(expected)]))
                .font(Theme.caption)
                .foregroundStyle(Theme.good)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken.joined(separator: ", "))
    }

    // MARK: Hold or sell: what a week's wait gains or costs

    private var holdCard: some View {
        let kg: Int = store.unitA.weightKg
        let now: Int = store.state.pricePer100kg
        let guntur: Market? = Simulation.markets.first { $0.fixedPrice == nil }
        let next: Int = max(guntur?.expectedNextWeek ?? now, now)
        let gain: Int = (next - now) * kg / 100
        let worth: Int = kg * now / 100
        let cost: Int = UnitSim.waitingCost(worth: worth, days: 7)
        let netGain: Int = gain - cost
        let worthWaiting: Bool = netGain > 0
        let safe: Int = UnitSim.safeDaysLeft(storedDays: 0, humidity: Simulation.storageHumidity)
        let verdictColor: Color = worthWaiting ? Theme.good : Theme.warn
        let verdictSymbol: String = worthWaiting ? "arrow.up.right.circle.fill" : "equal.circle.fill"
        let gainText: String = store.t("u_hold_gain", ["v": Fmt.rupees(next), "g": Fmt.rupees(gain), "kg": Fmt.kg(kg)])
        let costText: String = store.t("u_hold_cost", ["v": Fmt.rupees(cost)])
        let verdict: String = worthWaiting ? store.t("u_hold_net", ["v": Fmt.rupees(netGain)]) : store.t("u_hold_none")
        let safeText: String = store.t("u_hold_safe", ["d": "\(safe)"])
        let sellNow: Bool = store.state.advice == .sell

        return VStack(alignment: .leading, spacing: 10) {
            Label(store.t("u_hold_title"), systemImage: "hourglass")
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
            if sellNow {
                // The advice already says sell: do not show a "wait" gain that contradicts it.
                holdLine("indianrupeesign.circle.fill", store.t("u_hold_sell"), Theme.good)
                holdLine("indianrupeesign.circle", costText, Theme.inkMuted)
            } else {
                holdLine("chart.line.uptrend.xyaxis", gainText, Theme.ink)
                holdLine("indianrupeesign.circle", costText, Theme.inkMuted)
                holdLine(verdictSymbol, verdict, verdictColor)
            }
            holdLine("shippingbox.fill", safeText, Theme.ink)
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    private func holdLine(_ symbol: String, _ text: String, _ color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .frame(width: 26)
                .accessibilityHidden(true)
            Text(text)
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(Theme.headline)
    }

    // MARK: 30-day trend

    private var trendCard: some View {
        let prices = Simulation.priceHistory(current: store.state.pricePer100kg)
        let top = max(16_500, store.state.pricePer100kg + 500)
        let lastIndex: Int = max(0, prices.count - 1)
        let lastPrice: Int = prices.last ?? store.state.pricePer100kg
        return VStack(alignment: .leading, spacing: 8) {
            Text(store.t("last_30_days"))
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
            Chart {
                ForEach(prices.indices, id: \.self) { i in
                    AreaMark(x: .value("Day", i),
                             yStart: .value("Base", 11_000),
                             yEnd: .value("Price", prices[i]))
                        .foregroundStyle(Theme.chartFill)
                    LineMark(x: .value("Day", i), y: .value("Price", prices[i]))
                        .foregroundStyle(Theme.chartPrice)
                        .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round))
                }
                PointMark(x: .value("Day", lastIndex), y: .value("Price", lastPrice))
                    .foregroundStyle(Theme.ink)
                    .symbolSize(160)
            }
            .chartXAxis(.hidden)
            .chartYScale(domain: 11_000...top)
            .chartYAxis {
                AxisMarks(position: .leading, values: [12_000, 14_000, 16_000]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let n = value.as(Int.self) {
                            Text(Fmt.rupees(n)).font(Theme.caption)
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .card()
    }
}
