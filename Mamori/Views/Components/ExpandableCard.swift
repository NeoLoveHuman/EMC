import SwiftUI

/// The five folding cards on Home. Only one is open at a time.
enum HomeSection: Hashable {
    case status, weather, units, price, field
}

/// Sizes for the folded Home rows. Fonts are Theme fonts (nothing new).
enum HomeStyle {
    /// Key number on the right of a folded row: 24 pt heavy rounded.
    static let rowNumber: Font = Theme.widgetPrice
    /// One strong line.
    static let rowTitle: Font = Theme.headline
    /// Folded header height (plus 2 x 8 pt card padding = 72 pt rows).
    static let rowMinHeight: CGFloat = 56
    static let iconWidth: CGFloat = 30
    /// Open / close curve. nil under Reduce Motion (instant).
    static func spring(reduce: Bool) -> Animation? {
        Theme.motion(.spring(response: 0.38, dampingFraction: 0.86), reduce: reduce)
    }
}

/// A card whose header is always visible; tapping it reveals the content below.
/// The parent owns `isExpanded` (so Home can keep one card open at a time).
struct ExpandableCard<Header: View, Content: View>: View {
    @Environment(AppStore.self) private var store

    let isExpanded: Bool
    let summary: String
    let fill: Color
    let ink: Color
    let onToggle: () -> Void
    let header: Header
    let content: Content

    init(isExpanded: Bool,
         summary: String,
         fill: Color = Theme.surface,
         ink: Color = Theme.ink,
         onToggle: @escaping () -> Void,
         @ViewBuilder header: () -> Header,
         @ViewBuilder content: () -> Content) {
        self.isExpanded = isExpanded
        self.summary = summary
        self.fill = fill
        self.ink = ink
        self.onToggle = onToggle
        self.header = header()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerButton
            if isExpanded {
                expandedContent
            }
        }
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, Theme.space2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fill, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var headerButton: some View {
        let angle: Double = isExpanded ? 180 : 0
        let hintKey: String = isExpanded ? "home_expanded_hint" : "home_collapsed_hint"
        let hint: String = store.t(hintKey)
        return Button(action: onToggle) {
            HStack(spacing: Theme.space3) {
                header
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.down")
                    .font(Theme.label)
                    .foregroundStyle(ink)
                    .rotationEffect(.degrees(angle))
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, minHeight: HomeStyle.rowMinHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // A Button is already one VoiceOver element: replace its label with the full sentence.
        .accessibilityLabel(summary)
        .accessibilityHint(hint)
    }

    private var expandedContent: some View {
        let insertion: AnyTransition = AnyTransition.opacity.combined(with: .move(edge: .top))
        let transition: AnyTransition = AnyTransition.asymmetric(insertion: insertion, removal: .opacity)
        return content
            .padding(.top, Theme.space2)
            .padding(.bottom, Theme.space2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(transition)
    }
}

/// Standard folded row: icon, one strong line (+ optional small line), key number on the right.
struct HomeRowHeader: View {
    let symbol: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    let value: String
    var caption: String? = nil
    let ink: Color
    let muted: Color
    var valueColor: Color? = nil

    var body: some View {
        HStack(alignment: .center, spacing: Theme.space3) {
            Image(systemName: symbol)
                .font(Theme.sectionTitle)
                .foregroundStyle(iconColor)
                .frame(width: HomeStyle.iconWidth)
                .accessibilityHidden(true)
            titleColumn
            Spacer(minLength: Theme.space1)
            valueColumn
        }
    }

    private var titleColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(HomeStyle.rowTitle)
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.small)
                    .foregroundStyle(muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var valueColumn: some View {
        let numberColor: Color = valueColor ?? ink
        return VStack(alignment: .trailing, spacing: 0) {
            Text(value)
                .font(HomeStyle.rowNumber)
                .foregroundStyle(numberColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .contentTransition(.numericText())
            if let caption {
                Text(caption)
                    .font(Theme.small)
                    .foregroundStyle(muted)
                    .lineLimit(1)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(1)
    }
}

/// Small heading inside an open card.
struct HomeSubheading: View {
    let text: String
    let symbol: String
    let color: Color

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: symbol)
                .accessibilityHidden(true)
        }
        .font(Theme.smallBold)
        .foregroundStyle(color)
        .lineLimit(1)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Capsule button inside an open card (e.g. "See markets and sell").
/// Background + ink invert together in dark mode, so it stays readable on any card fill.
struct HomeActionButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.space2) {
                Text(title)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: symbol)
                    .accessibilityHidden(true)
            }
            .font(Theme.label)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, Theme.padding)
            .frame(maxWidth: .infinity, minHeight: Theme.minTap)
            .background(Theme.background, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
