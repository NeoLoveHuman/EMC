import SwiftUI

@main
struct MamoriApp: App {
    @State private var store = AppStore()

    init() {
        NotificationService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .mamoriAppearance()
                .onOpenURL { url in store.handle(url: url) }
                .task {
                    NotificationService.shared.requestPermission()
                    SpeechService.shared.prepare()
                    store.start()
                }
        }
    }
}

/// Four screens kept alive side by side, with our own bottom bar so the
/// voice button can sit in the middle of it on every screen.
///
/// Layout contract for every tab screen: the bar is a bottom safe-area inset, so
/// scroll views already stop above it. Add `.padding(.bottom, Theme.scrollBottomInset)`
/// to the scroll content so the last card also clears the mic that rises above the bar.
struct RootView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var store = store
        let quick: Animation? = Theme.motion(Theme.motionQuick, reduce: reduceMotion)
        ZStack {
            screen(.home) { DashboardView() }
            screen(.units) { HomeView() }
            screen(.network) { NetworkView() }
            screen(.record) { RecordView() }
        }
        .animation(quick, value: store.selectedTab)
        // The bubble sits in the content area, above the mic, so it never covers the bar.
        .overlay(alignment: .bottom) {
            VoiceBubble()
                .padding(.horizontal, Theme.padding)
                .padding(.bottom, Theme.voiceBubbleLift)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MamoriTabBar()
        }
        .tint(Theme.ink)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .animation(quick, value: store.voiceAnswer)
        .animation(quick, value: store.voiceQuestion)
        // Haptics: a tick on tab change, a warning buzz when a new alert lands.
        .sensoryFeedback(.selection, trigger: store.selectedTab)
        .sensoryFeedback(.warning, trigger: store.unreadAlerts) { oldValue, newValue in
            newValue > oldValue
        }
        // An answer belongs to the screen it was asked on.
        .onChange(of: store.selectedTab) { store.dismissVoice() }
        // Hidden presenter panel: triple-tap the title on Home or Units.
        .sheet(isPresented: $store.showDemoPanel) {
            DemoPanelView().environment(store)
        }
    }

    private func screen<Content: View>(_ tab: AppTab, @ViewBuilder _ content: () -> Content) -> some View {
        let active: Bool = store.selectedTab == tab
        let alpha: Double = active ? 1 : 0
        return content()
            .opacity(alpha)
            .allowsHitTesting(active)
            .accessibilityHidden(!active)
    }
}

// MARK: - Bottom bar with the voice button in the middle

struct MamoriTabBar: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            item(.home, key: "tab_home", symbol: "circle.circle.fill")
            item(.units, key: "tab_units", symbol: "square.stack.3d.up.fill")
            // Empty slot under the mic, so the four tabs stay evenly spaced.
            Color.clear
                .frame(width: Theme.micSlotWidth, height: Theme.tabItemHeight)
                .accessibilityHidden(true)
            item(.network, key: "tab_network", symbol: "point.3.connected.trianglepath.dotted")
            item(.record, key: "tab_record", symbol: "list.bullet.clipboard.fill")
        }
        .padding(.top, 6)
        .padding(.bottom, Theme.space1)
        .background(alignment: .top) { barBackground }
        // The mic rises above the bar's top edge. It is an overlay, so it never changes the bar's height.
        .overlay(alignment: .top) {
            MicButton()
                .offset(y: -Theme.micLift)
        }
    }

    /// Fills down under the home indicator on Face ID phones; on Home-button phones
    /// the bottom safe area is zero and the bar simply ends at the screen edge.
    private var barBackground: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
            Theme.surface
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func item(_ tab: AppTab, key: String, symbol: String) -> some View {
        let selected: Bool = store.selectedTab == tab
        let ink: Color = selected ? Theme.ink : Theme.inkStrong
        let title: String = store.t(key)
        return Button {
            store.selectedTab = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: symbol)
                    .font(Theme.tabIcon)
                    .accessibilityHidden(true)
                Text(title)
                    .font(Theme.tabLabelLarge)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                // Selected tab: a short ink bar under the label, so it is not shown by colour alone.
                Capsule()
                    .fill(selected ? Theme.ink : Theme.clear)
                    .frame(width: 18, height: 3)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(ink)
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.tabItemHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : [.isButton])
    }
}

/// Hold to talk, docked on the top edge of the tab bar on every screen.
/// Scripted: holding shows "Listening…"; releasing answers for whatever
/// screen is open. No real speech recognition (it would fail in a noisy hall).
///
/// The pressed look comes from @GestureState, which SwiftUI resets by itself when the
/// finger lifts or the gesture is cancelled (call, alert, sheet), so it cannot stick.
struct MicButton: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var pressing = false

    var body: some View {
        let busy: Bool = store.voiceThinking
        let pulse: Bool = (pressing || busy) && !reduceMotion
        let scale: CGFloat = pressing ? 1.1 : 1
        ZStack {
            Circle()
                .fill(Theme.surface)
                .frame(width: Theme.micOuter, height: Theme.micOuter)
                .overlay {
                    Circle().stroke(Theme.hairline, lineWidth: 1)
                }
            if busy {
                Circle()
                    .stroke(Theme.accent, lineWidth: 4)
                    .frame(width: Theme.micOuter - 4, height: Theme.micOuter - 4)
                    .transition(.opacity)
            }
            Circle()
                .fill(pressing ? Theme.accent : Theme.ink)
                .frame(width: Theme.micInner, height: Theme.micInner)
                .shadow(color: Theme.shadow, radius: 5, y: 2)
            Image(systemName: pressing ? "waveform" : "mic.fill")
                .font(Theme.micIcon)
                .foregroundStyle(pressing ? Theme.onAccent : Theme.onDark)
                .symbolEffect(.pulse, isActive: pulse)
        }
        .scaleEffect(scale)
        .animation(Theme.motion(.easeInOut(duration: 0.15), reduce: reduceMotion), value: pressing)
        .animation(Theme.motion(.easeInOut(duration: 0.2), reduce: reduceMotion), value: busy)
        .overlay(alignment: .top) {
            if pressing {
                listeningPill
            }
        }
        .contentShape(Circle())
        .gesture(pressGesture)
        // Light tap on touch-down, softer one on release.
        .sensoryFeedback(.impact(weight: .medium), trigger: pressing) { _, isDown in isDown }
        .sensoryFeedback(.impact(weight: .light), trigger: pressing) { wasDown, isDown in
            wasDown && !isDown
        }
        // Touch-down clears the previous answer, so "Listening…" never sits on top of an old bubble.
        .onChange(of: pressing) { _, isDown in
            if isDown { store.dismissVoice() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(store.t("ask_mamori"))
        .accessibilityHint(store.t("home_mic_hint"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { store.askNext() }
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { _, state, _ in state = true }
            .onEnded { value in
                // A finger that slid well off the button cancels the question.
                let moved: CGFloat = abs(value.translation.width) + abs(value.translation.height)
                if moved < 60 { store.askNext() }
            }
    }

    private var listeningPill: some View {
        Text(store.t("listening"))
            .font(Theme.label)
            .foregroundStyle(Theme.onAccent)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 14)
            .padding(.vertical, Theme.space2)
            .background(Theme.accent, in: Capsule())
            .shadow(color: Theme.shadow, radius: 6, y: 2)
            .offset(y: -46)
            .allowsHitTesting(false)
    }
}

/// The assistant's reply, shown just above the bar on any screen:
/// the question as the farmer's bubble, a short "thinking" pause, the answer,
/// then follow-up questions to tap. Tap anywhere on it (or ✕) to close.
struct VoiceBubble: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        if store.voiceQuestion != nil || store.voiceAnswer != nil {
            VStack(alignment: .trailing, spacing: Theme.space2) {
                if let question = store.voiceQuestion {
                    questionPill(question)
                }
                answerCard
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            // Clears itself so an old answer never sits on screen.
            .task(id: store.voiceAnswer) {
                guard store.voiceAnswer != nil else { return }
                try? await Task.sleep(for: .seconds(30))
                if !Task.isCancelled { store.dismissVoice() }
            }
        }
    }

    private func questionPill(_ question: String) -> some View {
        HStack(spacing: Theme.space2) {
            Image(systemName: "person.fill")
                .accessibilityHidden(true)
            Text(question)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .font(Theme.label)
        .foregroundStyle(Theme.onAccent)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Theme.accent, in: Capsule())
        .contentShape(Capsule())
        .onTapGesture { close() }
        .accessibilityHint(store.t("home_tap_close"))
    }

    private var answerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.accentOnInk)
                    .accessibilityHidden(true)
                answerText
                Spacer(minLength: 0)
                closeButton
            }
            if showSuggestions {
                suggestionChips
            }
        }
        .padding(Theme.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.ink, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .shadow(color: Theme.shadow, radius: 10, y: 4)
        // Tap on the card closes it; the chips and ✕ are buttons and win over this.
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .onTapGesture { close() }
    }

    @ViewBuilder
    private var answerText: some View {
        if store.voiceThinking {
            ThinkingDots(label: store.t("thinking"))
        } else if let answer = store.voiceAnswer {
            // Long Telugu / Hindi answers shrink a little rather than grow past the screen.
            Text(answer)
                .font(Theme.headline)
                .foregroundStyle(Theme.onDark)
                .lineLimit(9)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
        }
    }

    private var closeButton: some View {
        Button {
            close()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.onDark)
                .frame(width: Theme.minTap, height: Theme.minTap)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, -10)
        .padding(.trailing, -10)
        .accessibilityLabel(store.t("home_close"))
    }

    private var showSuggestions: Bool {
        !store.voiceThinking && store.voiceAnswer != nil && !store.voiceSuggestions.isEmpty
    }

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.space2) {
                ForEach(store.voiceSuggestions) { q in
                    Button {
                        store.ask(q)
                    } label: {
                        Text(store.t(q.key))
                            .font(Theme.label)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                            .padding(.horizontal, Theme.space3)
                            .frame(minHeight: Theme.minTap)
                            .background(Theme.background, in: Capsule())
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func close() {
        withAnimation { store.dismissVoice() }
    }
}

/// "Thinking…" with three dots that light up in turn.
struct ThinkingDots: View {
    let label: String

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.3)) { context in
            let phase: Int = Int(context.date.timeIntervalSinceReferenceDate / 0.3) % 3
            HStack(spacing: 6) {
                Text(label)
                    .font(Theme.headline)
                    .foregroundStyle(Theme.onDark)
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Theme.accentOnInk)
                        .frame(width: 8, height: 8)
                        .opacity(i == phase ? 1 : 0.3)
                }
            }
        }
    }
}
