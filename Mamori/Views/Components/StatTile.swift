import SwiftUI

struct StatTile: View {
    let title: String
    let value: String
    var symbol: String? = nil
    var valueColor: Color = Theme.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let symbol {
                Image(systemName: symbol)
                    .font(Theme.headline)
                    .foregroundStyle(Theme.ink)
                    .accessibilityHidden(true)
            }
            Text(value)
                .font(Theme.bigNumber)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .contentTransition(.numericText())
            Text(title)
                .font(Theme.small)
                .foregroundStyle(Theme.inkStrong)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.tileRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title + ", " + value)
    }
}

struct GradeBadge: View {
    @Environment(AppStore.self) private var store
    let grade: String

    var body: some View {
        Text(store.t("grade", ["g": grade]))
            .font(Theme.label)
            .foregroundStyle(Theme.onAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.accent, in: Capsule())
            .lineLimit(1)
    }
}
