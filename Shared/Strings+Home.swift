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
        "home_open_unit":     ["en": "Opens this unit", "te": "ఈ యూనిట్‌ను తెరుస్తుంది", "hi": "यह यूनिट खोलता है", "ja": "このユニットを開きます"],

        // Folding Home cards (ExpandableCard, HomeStatusCard, WeatherCard, HomeCards)
        "home_expanded_hint":  ["en": "Expanded. Double-tap to close.", "te": "తెరిచి ఉంది. మూసివేయడానికి రెండుసార్లు నొక్కండి.", "hi": "खुला है। बंद करने के लिए दो बार टैप करें।", "ja": "展開中。ダブルタップで閉じます。"],
        "home_collapsed_hint": ["en": "Collapsed. Double-tap to show more.", "te": "మూసి ఉంది. మరిన్ని చూడటానికి రెండుసార్లు నొక్కండి.", "hi": "बंद है। और देखने के लिए दो बार टैप करें।", "ja": "折りたたみ中。ダブルタップで詳細を表示します。"],
        "home_until_rain":     ["en": "until rain", "te": "వర్షానికి", "hi": "बारिश तक", "ja": "雨まで"],
        "home_worth_caption":  ["en": "Unit {id} today", "te": "యూనిట్ {id} నేడు", "hi": "यूनिट {id} आज", "ja": "ユニット{id} 本日"],
        "home_next":           ["en": "What happens next", "te": "తర్వాత ఏమి జరుగుతుంది", "hi": "आगे क्या होगा", "ja": "これからの予定"],
        "home_next_drying":    ["en": "{u}: day {d} of {t}, dry in {n} days, then bag and store", "te": "{u}: {t}లో {d}వ రోజు, {n} రోజుల్లో ఆరుతుంది, తర్వాత బస్తాల్లో నింపి నిల్వ", "hi": "{u}: {t} में से दिन {d}, {n} दिन में सूखेगी, फिर बोरी में भरकर भंडारण", "ja": "{u}：{t}日中{d}日目、あと{n}日で乾燥、その後袋詰めして保管"],
        "home_next_soon":      ["en": "{u}: day {d} of {t}, almost dry, then bag and store", "te": "{u}: {t}లో {d}వ రోజు, దాదాపు ఆరింది, తర్వాత బస్తాల్లో నింపి నిల్వ", "hi": "{u}: {t} में से दिन {d}, लगभग सूखी, फिर बोरी में भरकर भंडारण", "ja": "{u}：{t}日中{d}日目、まもなく乾燥、その後袋詰めして保管"],
        "home_next_ready":     ["en": "{u}: dry now, bag and store it or sell", "te": "{u}: ఇప్పుడు ఆరింది, బస్తాల్లో నింపి నిల్వ చేయండి లేదా అమ్మండి", "hi": "{u}: अब सूख गई, बोरी में भरकर रखें या बेचें", "ja": "{u}：乾燥完了。袋詰めして保管、または販売"],
        "home_next_stored":    ["en": "{u}: stored, {b} bags · {kg}, ready to sell", "te": "{u}: నిల్వలో, {b} బస్తాలు · {kg}, అమ్మకానికి సిద్ధం", "hi": "{u}: भंडार में, {b} बोरी · {kg}, बिक्री के लिए तैयार", "ja": "{u}：保管中、{b}袋 · {kg}、販売可能"],
        "home_ready_sell":     ["en": "Ready to sell", "te": "అమ్మకానికి సిద్ధం", "hi": "बिक्री के लिए तैयार", "ja": "販売可能"],
        "home_nothing_ready":  ["en": "Nothing is ready to sell yet", "te": "ఇంకా అమ్మకానికి ఏదీ సిద్ధంగా లేదు", "hi": "अभी बेचने के लिए कुछ तैयार नहीं है", "ja": "販売できる作物はまだありません"],
        "home_worth_total":    ["en": "Worth at today's price", "te": "నేటి ధరకు విలువ", "hi": "आज के दाम पर कीमत", "ja": "本日の価格での価値"],
        "home_price_line":     ["en": "Guntur today: {v} per 100 kg, {p}% this week", "te": "నేడు గుంటూరు: 100 కిలోకు {v}, ఈ వారం {p}%", "hi": "आज गुंटूर: {v} प्रति 100 किलो, इस हफ़्ते {p}%", "ja": "本日のグントゥール：100kgあたり{v}、今週{p}%"],
        "home_best_market":    ["en": "Best market: {m}, {k} · {net}", "te": "ఉత్తమ మార్కెట్: {m}, {k} · {net}", "hi": "सबसे अच्छा बाज़ार: {m}, {k} · {net}", "ja": "最適な市場：{m}、{k} · {net}"],
        "home_go_sell":        ["en": "See markets and sell", "te": "మార్కెట్లు చూసి అమ్మండి", "hi": "बाज़ार देखें और बेचें", "ja": "市場を見て販売する"],
        "home_wx_good":        ["en": "Good drying", "te": "ఆరబెట్టడానికి అనుకూలం", "hi": "सुखाने के लिए अच्छा", "ja": "乾燥に好適"],
        "home_wx_slow":        ["en": "Slow drying", "te": "నెమ్మదిగా ఆరుతుంది", "hi": "धीमी सुखाई", "ja": "乾燥が遅い"],
        "home_wx_cover":       ["en": "Rain: crop covered", "te": "వర్షం: పంట కప్పబడింది", "hi": "बारिश: फसल ढकी है", "ja": "雨：作物は保護中"],
        "home_next_hours":     ["en": "Next 3 hours", "te": "తదుపరి 3 గంటలు", "hi": "अगले 3 घंटे", "ja": "この先3時間"],
        "home_rest_today":     ["en": "Rest of today", "te": "ఈరోజు మిగతా సమయం", "hi": "आज का बाकी दिन", "ja": "今日のこの後"],
        "home_next_days":      ["en": "Next 3 days", "te": "తదుపరి 3 రోజులు", "hi": "अगले 3 दिन", "ja": "この先3日間"],
        "home_day_good":       ["en": "Good", "te": "అనుకూలం", "hi": "अच्छा", "ja": "好適"],
        "home_day_slow":       ["en": "Slow", "te": "నెమ్మది", "hi": "धीमा", "ja": "遅い"],
        "home_day_cover":      ["en": "Cover", "te": "కప్పండి", "hi": "ढकें", "ja": "覆う"]
    ]
}
