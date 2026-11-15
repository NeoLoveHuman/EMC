import Foundation

/// Extra translations (Home). Same format as L10n.table: every key needs en, te, hi, ja.
extension L10n {
    static let extraHome: [String: [String: String]] = [
        "home_status_safe":   ["en": "All safe", "te": "అంతా సురక్షితం", "hi": "सब सुरक्षित", "ja": "すべて安全"],
        "home_status_sell":   ["en": "Good price: sell now", "te": "మంచి ధర: ఇప్పుడే అమ్మండి", "hi": "अच्छा दाम: अभी बेचें", "ja": "好価格：今が売り時"],
        "home_dry_in":        ["en": "Unit {id} dry in {d} days", "te": "యూనిట్ {id} {d} రోజుల్లో ఆరుతుంది", "hi": "यूनिट {id} {d} दिन में सूखेगी", "ja": "ユニット{id}はあと{d}日で乾燥"],
        "home_dry_soon":      ["en": "Unit {id} almost dry", "te": "యూనిట్ {id} దాదాపు ఆరింది", "hi": "यूनिट {id} लगभग सूख गई", "ja": "ユニット{id}はまもなく乾燥"],
        "home_dry_done":      ["en": "Unit {id} is dry and ready", "te": "యూనిట్ {id} ఆరింది, సిద్ధం", "hi": "यूनिट {id} सूख गई, तैयार", "ja": "ユニット{id}は乾燥完了"],
        "home_worth":         ["en": "Unit {id} is worth today", "te": "యూనిట్ {id} నేటి విలువ", "hi": "यूनिट {id} की आज की कीमत", "ja": "ユニット{id}の本日の価値"],
        "home_alerts_new":    ["en": "{n} new", "te": "{n} కొత్తవి", "hi": "{n} नई", "ja": "新着{n}件"],
        "home_new":           ["en": "New", "te": "కొత్తది", "hi": "नई", "ja": "新着"],
        "home_alerts_empty_title": ["en": "All quiet", "te": "అంతా ప్రశాంతం", "hi": "सब शांत है", "ja": "お知らせはありません"],
        "home_alerts_empty_body":  ["en": "Mamori will tell you when rain is coming or the price moves.", "te": "వర్షం వచ్చేటప్పుడు లేదా ధర మారినప్పుడు మామోరి మీకు చెబుతుంది.", "hi": "बारिश आने या दाम बदलने पर मामोरी आपको बताएगा।", "ja": "雨が近づいたときや価格が動いたときにMamoriがお知らせします。"],
        "home_mic_hint":      ["en": "Asks Mamori about this screen and reads the answer aloud", "te": "ఈ స్క్రీన్ గురించి మామోరిని అడిగి, జవాబు చదివి వినిపిస్తుంది", "hi": "इस स्क्रीन के बारे में मामोरी से पूछता है और जवाब पढ़कर सुनाता है", "ja": "この画面についてMamoriに聞き、答えを読み上げます"],
        "home_close":         ["en": "Close", "te": "మూసివేయండి", "hi": "बंद करें", "ja": "閉じる"],
        "home_tap_close":     ["en": "Tap to close", "te": "మూసివేయడానికి నొక్కండి", "hi": "बंद करने के लिए टैप करें", "ja": "タップで閉じる"],
        "home_language":      ["en": "Language", "te": "భాష", "hi": "भाषा", "ja": "言語"],
        "home_degrees":       ["en": "{t} degrees", "te": "{t} డిగ్రీలు", "hi": "{t} डिग्री", "ja": "{t}度"],
        "home_open_unit":     ["en": "Opens this unit", "te": "ఈ యూనిట్‌ను తెరుస్తుంది", "hi": "यह यूनिट खोलता है", "ja": "このユニットを開きます"]
    ]
}
