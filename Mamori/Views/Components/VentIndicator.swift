import SwiftUI

struct VentIndicator: View {
    @Environment(AppStore.self) private var store
    let state: VentState
    var large: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var symbol: String {
        switch state {
        case .open:    return "wind"
        case .closing: return "arrow.down.circle.fill"
        case .closed:  return "lock.fill"
        }
    }

    private var key: String {
        switch state {
        case .open:    return "vent_open"
        case .closing: return "vent_closing"
        case .closed:  return "vent_closed"
        }
    }

    private var background: Color {
        switch state {
        case .open:    return Theme.accent
        case .closing: return Theme.warn
        case .closed:  return Theme.ink
        }
    }

    private var foreground: Color {
        state == .open ? Theme.onAccent : Theme.onDark
    }

    var body: some View {
        let pulse: Bool = state == .closing && !reduceMotion
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .symbolEffect(.pulse, isActive: pulse)
                .accessibilityHidden(true)
            Text(store.t(key))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .font(large ? Theme.headline : Theme.label)
        .foregroundStyle(foreground)
        .padding(.horizontal, large ? 16 : 12)
        .padding(.vertical, large ? 10 : 6)
        .background(background, in: Capsule())
        .animation(Theme.motion(.easeInOut(duration: 0.4), reduce: reduceMotion), value: state)
    }
}
