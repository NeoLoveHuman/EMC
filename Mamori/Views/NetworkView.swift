import SwiftUI

/// Network tab. Sell = markets, price, advice, price alert, buyer network.
/// Buy (seeds, fertilisers, expert help) exists but is hidden by Features.showBuy.
struct NetworkView: View {
    @Environment(AppStore.self) private var store
    @State private var side = 0     // 0 = sell, 1 = buy

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacing) {
                    if Features.showBuy {
                        SegmentSwitch(titles: [store.t("tab_sell"), store.t("buy_tab")],
                                      symbols: ["arrow.up.right.circle.fill", "cart.fill"],
                                      index: $side)
                    }
                    if side == 1 && Features.showBuy {
                        BuyView()
                    } else {
                        SellView()
                    }
                }
                .padding(Theme.padding)
                // Room for the custom tab bar and the floating mic.
                .padding(.bottom, Theme.scrollBottomInset)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .mamoriToolbar()
        }
    }
}
