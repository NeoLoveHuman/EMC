import Foundation
import UserNotifications

/// Local notifications only (free Apple ID: no push, no server).
final class NotificationService: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {

    static let shared = NotificationService()

    /// When on, an alert that arrives while the app is open is also read aloud.
    var speakAlerts = false

    private var center: UNUserNotificationCenter { UNUserNotificationCenter.current() }

    /// The delayed read-aloud of an arriving alert. Only touched on the main queue.
    private var pendingSpeech: DispatchWorkItem?

    /// Call as early as possible (App init) so banners show while the app is open.
    func configure() {
        center.delegate = self
    }

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Same as requestPermission, but waits for the answer. Used by Pre-flight so the
    /// system prompt is answered before stage, never during the demo.
    func requestPermissionAndWait() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Current permission, for the demo panel's status section.
    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    /// Plain-English label for a permission state.
    static func label(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Allowed"
        case .denied: return "DENIED: Settings > Mamori > Notifications"
        case .notDetermined: return "Not asked yet: run Pre-flight"
        case .provisional: return "Provisional (quiet)"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    /// Cancels an alert that is waiting to be read aloud. Call on the main queue.
    func cancelPendingSpeech() {
        pendingSpeech?.cancel()
        pendingSpeech = nil
    }

    func schedule(title: String, body: String, after seconds: Double, lang: String = "en") {
        // A new scene: an older alert must not start talking over it.
        cancelPendingSpeech()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["lang": lang]
        // .timeSensitive needs an entitlement the free account does not get: left at default.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request) { _ in }
    }

    func clearAll() {
        cancelPendingSpeech()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        center.setBadgeCount(0) { _ in }
    }

    // Show the banner even when Mamori is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if speakAlerts {
            let body = notification.request.content.body
            let lang = notification.request.content.userInfo["lang"] as? String ?? "en"
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.cancelPendingSpeech()
                let work = DispatchWorkItem {
                    guard SpeechService.shared.hasVoice(lang) else { return }
                    let spoken = body.replacingOccurrences(of: "₹", with: L10n.t("rupees_spoken", lang))
                    SpeechService.shared.speak(spoken, lang: lang)
                }
                self.pendingSpeech = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
            }
        }
        completionHandler([.banner, .sound, .list])
    }
}
