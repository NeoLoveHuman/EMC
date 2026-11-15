import SwiftUI

/// Large two-or-more-way switch (My farm | Hub, Sell | Buy), readable on a projector.
struct SegmentSwitch: View {
    let titles: [String]
    let symbols: [String]
    @Binding var index: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(titles.indices, id: \.self) { i in
                let selected = index == i
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { index = i }
                } label: {
                    Label(titles[i], systemImage: symbols[i])
                        .font(Theme.headline)
                        .foregroundStyle(selected ? Theme.onDark : Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, minHeight: Theme.minTap)
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                        .background(selected ? Theme.ink : Theme.clear,
                                    in: RoundedRectangle(cornerRadius: Theme.tileRadius))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(6)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}
