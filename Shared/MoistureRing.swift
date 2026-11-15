import SwiftUI

/// Ring that fills from harvest moisture (empty) to the 11% target (full).
/// The target marker sits at 12 o'clock, where the ring completes.
/// Lives in Shared/ because the widget uses it too.
struct MoistureRing: View {
    var moisture: Double
    var size: CGFloat
    var lineWidth: CGFloat = Theme.ringLineWidth
    var showTargetMarker: Bool = true
    var numberFont: Font = Theme.ringNumber
    var caption: String? = nil
    /// Fill the ring from empty when it first appears (app screens only; the widget leaves this off).
    var animateOnAppear: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared: Bool = false

    private var progress: Double { Simulation.dryingProgress(moisture: moisture) }
    private var shownProgress: Double {
        let waiting: Bool = animateOnAppear && !appeared
        return waiting ? 0 : progress
    }
    private var changeAnimation: Animation? {
        Theme.motion(.easeInOut(duration: 0.6), reduce: reduceMotion)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.ringTrack, lineWidth: lineWidth)
                .padding(lineWidth / 2)
            Circle()
                .trim(from: 0, to: shownProgress)
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(lineWidth / 2)
            if showTargetMarker {
                Capsule()
                    .fill(Theme.ink)
                    .frame(width: 4, height: lineWidth + 8)
                    .offset(y: -(size / 2 - lineWidth / 2))
            }
            VStack(spacing: 0) {
                Text(Fmt.percent1(moisture))
                    .font(numberFont)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .contentTransition(.numericText())
                if let caption {
                    Text(caption)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.inkMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .padding(lineWidth * 1.3)
        }
        .frame(width: size, height: size)
        .animation(changeAnimation, value: moisture)
        .onAppear { fillOnAppear() }
    }

    private func fillOnAppear() {
        guard animateOnAppear, !appeared else { return }
        if reduceMotion {
            appeared = true
        } else {
            withAnimation(Theme.motionRing) { appeared = true }
        }
    }
}
