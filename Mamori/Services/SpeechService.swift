import Foundation
import AVFoundation

/// Speaks text aloud with the system voices. Works offline.
/// If the phone has no voice for a language, callers fall back to English.
final class SpeechService: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {

    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Call once at launch so the first answer does not lag.
    func prepare() {
        // .playback so it is heard even with the silent switch on.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        _ = AVSpeechSynthesisVoice.speechVoices()
    }

    static func voiceCode(_ lang: String) -> String {
        switch lang {
        case "te": return "te-IN"
        case "hi": return "hi-IN"
        case "ja": return "ja-JP"
        default:   return "en-IN"
        }
    }

    private func voice(_ lang: String) -> AVSpeechSynthesisVoice? {
        let code = Self.voiceCode(lang)
        if let exact = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language == code }) {
            return exact
        }
        if lang == "en" {
            return AVSpeechSynthesisVoice(language: "en-US") ?? AVSpeechSynthesisVoice(language: "en-GB")
        }
        return nil
    }

    /// How many voices the phone has for an exact code such as "te-IN" (demo panel status).
    static func installedVoiceCount(_ code: String) -> Int {
        AVSpeechSynthesisVoice.speechVoices().filter { $0.language == code }.count
    }

    /// True when this phone can speak the language.
    func hasVoice(_ lang: String) -> Bool { voice(lang) != nil }

    func speak(_ text: String, lang: String) {
        guard let voice = voice(lang) else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
    }

    // Give the audio back to other apps when the voice finishes.
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
