import SwiftUI
import UserNotifications

/// Hidden presenter controls. Opened by triple-tapping "Mamori" on Home.
/// Each scene changes state, adds an alert, reloads the widget and schedules
/// a local notification after the chosen delay. The panel closes itself so
/// you can go straight to the home screen.
/// Presenter-only, so its text is English and not in the translation tables.
struct DemoPanelView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// Last time each scene fired: a second tap within 1.5 s is ignored.
    @State private var lastFired: [String: Date] = [:]
    /// Scene that just fired: shows a tick until the panel closes.
    @State private var tickedScene: String?
    @State private var notificationStatus: UNAuthorizationStatus?
    @State private var voiceCounts: [String: Int] = [:]
    @State private var preflightRunning: Bool = false
    @State private var preflightDone: Bool = false

    private static let debounceSeconds: TimeInterval = 1.5
    private static let voiceCodes: [String] = ["te-IN", "hi-IN", "ja-JP", "en-IN"]

    var body: some View {
        NavigationStack {
            List {
                preflightSection
                scenesSection
                statusSection
                voiceSection
                delaySection
                resetSection
            }
            .navigationTitle("Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await refreshStatus() }
        }
    }

    // MARK: - Sections

    private var preflightSection: some View {
        Section {
            Button {
                runPreflight()
            } label: {
                Label(preflightTitle, systemImage: preflightDone ? "checkmark.seal.fill" : "airplane.departure")
                    .font(Theme.headline)
                    .padding(.vertical, 6)
            }
            .disabled(preflightRunning)
        } footer: {
            Text(verbatim: "Resets the demo and asks for notification permission now, so the system prompt never appears on stage.")
        }
    }

    private var preflightTitle: String {
        if preflightRunning { return "Pre-flight running…" }
        return preflightDone ? "Pre-flight done" : "Pre-flight"
    }

    private var scenesSection: some View {
        Section("Scenes") {
            sceneButton("Rain in 40 min", symbol: "cloud.rain.fill") { store.demoRain() }
            sceneButton("Batch almost dry", symbol: "sun.max.fill") { store.demoAlmostDry() }
            sceneButton("Price jump", symbol: "chart.line.uptrend.xyaxis") { store.demoPriceJump() }
            sceneButton("Price alert hit (₹16,000 or the set target)", symbol: "bell.badge.fill") { store.demoPriceTargetHit() }
        }
    }

    private var statusSection: some View {
        Section("Status") {
            statusRow("App Group shared", SharedStore.isShared ? "Yes" : "NO: widget will not follow", ok: SharedStore.isShared)
            statusRow("Notifications", notificationText, ok: notificationStatus == .authorized)
            ForEach(Self.voiceCodes, id: \.self) { code in
                statusRow("Voice " + code, voiceText(code), ok: (voiceCounts[code] ?? 0) > 0)
            }
            statusRow("Unit A", unitAText, ok: unitALooksRight)
            statusRow("Rain", rainText, ok: true)
            Button("Refresh status") {
                Task { await refreshStatus() }
            }
        }
    }

    private var voiceSection: some View {
        Section("Voice") {
            Toggle("Speak alerts aloud (while the app is open)", isOn: speakAlertsBinding)
        }
    }

    private var delaySection: some View {
        Section("Notification delay") {
            Picker("Delay", selection: delayBinding) {
                Text(verbatim: "5 s").tag(5.0)
                Text(verbatim: "10 s").tag(10.0)
            }
            .pickerStyle(.segmented)
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                store.resetDemo()
                dismiss()
            } label: {
                Label("Reset demo", systemImage: "arrow.counterclockwise")
                    .font(Theme.headline)
            }
        }
    }

    // MARK: - Bindings

    private var speakAlertsBinding: Binding<Bool> {
        Binding(
            get: { store.speakAlerts },
            set: { newValue in
                store.speakAlerts = newValue
                NotificationService.shared.speakAlerts = newValue
            }
        )
    }

    private var delayBinding: Binding<Double> {
        Binding(
            get: { store.notificationDelay },
            set: { newValue in store.notificationDelay = newValue }
        )
    }

    // MARK: - Status text

    private var notificationText: String {
        guard let status = notificationStatus else { return "Checking…" }
        return NotificationService.label(status)
    }

    private func voiceText(_ code: String) -> String {
        let n: Int = voiceCounts[code] ?? 0
        if n > 0 { return "\(n) installed" }
        if code == "en-IN" { return "none: speaks with en-US" }
        return "none: speaks English instead"
    }

    private var unitAText: String {
        let day: Double = store.unitADayNow
        let moisture: Double = store.unitAMoistureNow
        return String(format: "day %.1f · %.1f%%", day, moisture)
    }

    /// Expected right after a reset: day 12.x, moisture 11.x%.
    private var unitALooksRight: Bool {
        let day: Double = store.unitADayNow
        return day >= 12 && day < 13
    }

    private var rainText: String {
        guard let mins = store.rainMinutesLeftNow else { return "none" }
        return "in \(mins) min"
    }

    private func statusRow(_ label: String, _ value: String, ok: Bool) -> some View {
        HStack {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(ok ? Theme.good : Theme.danger)
            Text(verbatim: label)
            Spacer()
            Text(verbatim: value)
                .foregroundStyle(ok ? Theme.inkMuted : Theme.danger)
                .multilineTextAlignment(.trailing)
        }
        .font(.footnote)
    }

    // MARK: - Actions

    private func sceneButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        let ticked: Bool = tickedScene == title
        return Button {
            fire(title, action)
        } label: {
            HStack {
                Label(title, systemImage: symbol)
                    .font(Theme.headline)
                Spacer()
                if ticked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.good)
                        .transition(.scale)
                }
            }
            .padding(.vertical, 6)
        }
    }

    /// Fires a scene once. A second tap within 1.5 s (or any tap while the
    /// panel is closing) is ignored, so a double tap never sends two alerts.
    private func fire(_ title: String, _ action: () -> Void) {
        let now = Date()
        if tickedScene != nil { return }
        if let last = lastFired[title], now.timeIntervalSince(last) < Self.debounceSeconds { return }
        lastFired[title] = now
        withAnimation { tickedScene = title }
        action()
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            dismiss()
        }
    }

    private func runPreflight() {
        preflightRunning = true
        preflightDone = false
        store.resetDemo()
        Task {
            _ = await NotificationService.shared.requestPermissionAndWait()
            await refreshStatus()
            preflightRunning = false
            preflightDone = true
        }
    }

    private func refreshStatus() async {
        var counts: [String: Int] = [:]
        for code in Self.voiceCodes {
            counts[code] = SpeechService.installedVoiceCount(code)
        }
        voiceCounts = counts
        notificationStatus = await NotificationService.shared.authorizationStatus()
    }
}
