import SwiftUI

/// One thing the farmer can order or request on the Buy side.
/// PLACEHOLDER items and prices (not in the spec): check before the pitch.
struct BuyItem: Identifiable {
    let id: String            // translation keys: "item_<id>" and "item_<id>_d"
    let symbol: String
    let price: Int?           // nil = a request (expert help), not a purchase
}

struct BuySection: Identifiable {
    let id: String            // translation key of the section title
    let items: [BuyItem]

    static let all: [BuySection] = [
        BuySection(id: "buy_seeds", items: [
            BuyItem(id: "seed_hybrid", symbol: "leaf.fill", price: 600),
            BuyItem(id: "seedlings", symbol: "tree.fill", price: 150)
        ]),
        BuySection(id: "buy_fert", items: [
            BuyItem(id: "npk", symbol: "drop.fill", price: 2_400),
            BuyItem(id: "neem", symbol: "shippingbox.fill", price: 1_200)
        ]),
        BuySection(id: "buy_expert", items: [
            BuyItem(id: "agro", symbol: "phone.fill", price: nil),
            BuyItem(id: "photo", symbol: "camera.fill", price: nil)
        ])
    ]
}

/// Buy side of the Network tab (content only). Nothing is really ordered:
/// the button just flips to "Requested".
struct BuyView: View {
    @Environment(AppStore.self) private var store
    @State private var requested: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            ForEach(BuySection.all) { section in
                VStack(alignment: .leading, spacing: 0) {
                    Text(store.t(section.id))
                        .font(Theme.sectionTitle)
                        .foregroundStyle(Theme.ink)
                        .padding(.bottom, 6)
                    ForEach(section.items) { item in
                        row(item)
                        if item.id != section.items.last?.id { Divider() }
                    }
                }
                .card()
            }
        }
    }

    private func row(_ item: BuyItem) -> some View {
        let done = requested.contains(item.id)
        return HStack(alignment: .center, spacing: 12) {
            Image(systemName: item.symbol)
                .font(Theme.headline)
                .foregroundStyle(Theme.onAccent)
                .frame(width: 44, height: 44)
                .background(Theme.accent, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(store.t("item_\(item.id)"))
                    .font(Theme.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail(item))
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Button {
                withAnimation { _ = requested.insert(item.id) }
            } label: {
                Text(store.t(done ? "requested" : (item.price == nil ? "request" : "order")))
                    .font(Theme.label)
                    .foregroundStyle(done ? Theme.onDark : Theme.onDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(minHeight: 44)
                    .background(done ? Theme.good : Theme.ink, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(done)
        }
        .padding(.vertical, 10)
    }

    private func detail(_ item: BuyItem) -> String {
        let d = store.t("item_\(item.id)_d")
        if let price = item.price { return d + " · " + Fmt.rupees(price) }
        return d
    }
}
