import Foundation

struct Language: Identifiable, Equatable {
    let code: String
    let name: String
    let short: String
    var id: String { code }
}

/// In-app translations. Not system localisation, so the switch is instant on stage.
/// Placeholders are written as {name} and filled by `t(key, lang, ["name": value])`.
enum L10n {

    static let languages: [Language] = [
        Language(code: "en", name: "English", short: "EN"),
        Language(code: "te", name: "తెలుగు", short: "తె"),
        Language(code: "hi", name: "हिन्दी", short: "हि"),
        Language(code: "ja", name: "日本語", short: "日本")
    ]

    static func short(_ code: String) -> String {
        languages.first { $0.code == code }?.short ?? code.uppercased()
    }

    static func t(_ key: String, _ lang: String, _ args: [String: String] = [:]) -> String {
        let row: [String: String]? = table[key] ?? extraCore[key] ?? extraHome[key] ?? extraUnits[key]
        var s = row?[lang] ?? row?["en"] ?? key
        for (k, v) in args { s = s.replacingOccurrences(of: "{\(k)}", with: v) }
        return s
    }

    /// Locale for dates. All four use Western digits by default.
    static func locale(_ lang: String) -> Locale {
        switch lang {
        case "te": return Locale(identifier: "te_IN")
        case "hi": return Locale(identifier: "hi_IN")
        case "ja": return Locale(identifier: "ja_JP")
        default:   return Locale(identifier: "en_IN")
        }
    }

    static let table: [String: [String: String]] = [
        // Tabs and chrome
        "tab_home":   ["en": "Home", "te": "హోమ్", "hi": "होम", "ja": "ホーム"],
        "tab_sell":   ["en": "Sell", "te": "అమ్మకం", "hi": "बेचें", "ja": "販売"],
        "tab_record": ["en": "Record", "te": "రికార్డు", "hi": "रिकॉर्ड", "ja": "記録"],
        "alerts":     ["en": "Alerts", "te": "హెచ్చరికలు", "hi": "सूचनाएँ", "ja": "通知"],
        "done":       ["en": "Done", "te": "సరే", "hi": "ठीक है", "ja": "完了"],

        // Home
        "my_units":  ["en": "My units", "te": "నా యూనిట్లు", "hi": "मेरी यूनिट", "ja": "マイユニット"],
        "no_rain":   ["en": "No rain expected", "te": "వర్షం సూచన లేదు", "hi": "बारिश की संभावना नहीं", "ja": "雨の予報なし"],
        "rain_in":   ["en": "Rain in {n} min", "te": "{n} నిమిషాల్లో వర్షం", "hi": "{n} मिनट में बारिश", "ja": "{n}分後に雨"],
        "unit":      ["en": "Unit {id}", "te": "యూనిట్ {id}", "hi": "यूनिट {id}", "ja": "ユニット{id}"],
        "mode_drying":  ["en": "Drying", "te": "ఆరబెడుతోంది", "hi": "सुखाई जारी", "ja": "乾燥中"],
        "mode_storing": ["en": "Storing", "te": "నిల్వలో", "hi": "भंडारण में", "ja": "保管中"],
        "day_of":    ["en": "Day {d} of {t}", "te": "{t}లో {d}వ రోజు", "hi": "दिन {d} / {t}", "ja": "{t}日中 {d}日目"],
        "days_left": ["en": "{d} days left", "te": "ఇంకా {d} రోజులు", "hi": "{d} दिन बाकी", "ja": "あと{d}日"],
        "in_storage_day": ["en": "In storage · day {d}", "te": "నిల్వలో · {d}వ రోజు", "hi": "भंडारण में · दिन {d}", "ja": "保管 {d}日目"],
        "ready":     ["en": "Dry · ready", "te": "ఆరింది · సిద్ధం", "hi": "सूख गई · तैयार", "ja": "乾燥完了"],
        "vent_open":    ["en": "Vents open", "te": "వెంట్లు తెరిచి ఉన్నాయి", "hi": "वेंट खुले हैं", "ja": "通気口：開"],
        "vent_closing": ["en": "Vents closing", "te": "వెంట్లు మూసుకుంటున్నాయి", "hi": "वेंट बंद हो रहे हैं", "ja": "通気口：閉鎖中"],
        "vent_closed":  ["en": "Vents closed", "te": "వెంట్లు మూసి ఉన్నాయి", "hi": "वेंट बंद हैं", "ja": "通気口：閉"],
        "grade":     ["en": "Grade {g}", "te": "గ్రేడ్ {g}", "hi": "ग्रेड {g}", "ja": "等級 {g}"],

        // Batch detail
        "moisture":  ["en": "Moisture", "te": "తేమ", "hi": "नमी", "ja": "水分"],
        "target":    ["en": "Target {n}%", "te": "లక్ష్యం {n}%", "hi": "लक्ष्य {n}%", "ja": "目標 {n}%"],
        "drying_curve":  ["en": "Drying curve", "te": "ఆరబెట్టే వక్రం", "hi": "सुखाई वक्र", "ja": "乾燥曲線"],
        "fourteen_vs":   ["en": "{a} days instead of {b}", "te": "{b} కాదు, {a} రోజులు", "hi": "{b} नहीं, {a} दिन", "ja": "{b}日ではなく{a}日"],
        "series_unit":   ["en": "Harvest Protector", "te": "హార్వెస్ట్ ప్రొటెక్టర్", "hi": "हार्वेस्ट प्रोटेक्टर", "ja": "ハーベスト・プロテクター"],
        "series_ground": ["en": "Open ground", "te": "నేలపై ఆరబెట్టడం", "hi": "खुली ज़मीन", "ja": "地面での天日干し"],
        "days_n":    ["en": "{d} days", "te": "{d} రోజులు", "hi": "{d} दिन", "ja": "{d}日間"],
        "vents":     ["en": "Vents", "te": "వెంట్లు", "hi": "वेंट", "ja": "通気口"],
        "open_vents":  ["en": "Open vents", "te": "వెంట్లు తెరవండి", "hi": "वेंट खोलें", "ja": "通気口を開く"],
        "close_vents": ["en": "Close vents", "te": "వెంట్లు మూయండి", "hi": "वेंट बंद करें", "ja": "通気口を閉じる"],
        "closed_auto": ["en": "Closed automatically: rain expected", "te": "వర్షం వస్తోంది: ఆటోమేటిక్‌గా మూసుకున్నాయి", "hi": "अपने आप बंद: बारिश आने वाली है", "ja": "雨の予報のため自動で閉じました"],
        "camera":    ["en": "Camera check", "te": "కెమెరా తనిఖీ", "hi": "कैमरा जाँच", "ja": "カメラ検査"],
        "colour":    ["en": "Colour", "te": "రంగు", "hi": "रंग", "ja": "色"],
        "mould_risk": ["en": "Mould risk", "te": "బూజు ప్రమాదం", "hi": "फफूंद का खतरा", "ja": "カビのリスク"],
        "checked_ago": ["en": "Checked {m} min ago", "te": "{m} నిమిషాల క్రితం తనిఖీ", "hi": "{m} मिनट पहले जाँचा", "ja": "{m}分前に確認"],
        "temp_inside":     ["en": "Temperature inside", "te": "లోపలి ఉష్ణోగ్రత", "hi": "अंदर का तापमान", "ja": "内部温度"],
        "humidity_inside": ["en": "Humidity inside", "te": "లోపలి తేమ", "hi": "अंदर की नमी", "ja": "内部湿度"],
        "weight":    ["en": "Dry weight", "te": "ఎండు బరువు", "hi": "सूखा वज़न", "ja": "乾燥重量"],
        "bags":      ["en": "{n} bags", "te": "{n} బస్తాలు", "hi": "{n} बोरियाँ", "ja": "{n}袋"],

        // Sell
        "market_today": ["en": "Guntur market yard · today", "te": "గుంటూరు మార్కెట్ యార్డ్ · ఈరోజు", "hi": "गुंटूर मंडी · आज", "ja": "グントゥール市場 · 今日"],
        "per_100kg":    ["en": "per 100 kg", "te": "100 కిలోలకు", "hi": "प्रति 100 किलो", "ja": "100kgあたり"],
        "vs_last_week": ["en": "{p}% vs last week", "te": "గత వారం కంటే {p}%", "hi": "पिछले हफ़्ते से {p}%", "ja": "先週比 {p}%"],
        "last_30_days": ["en": "Last 30 days", "te": "గత 30 రోజులు", "hi": "पिछले 30 दिन", "ja": "過去30日"],
        "hold":  ["en": "HOLD", "te": "ఆగండి", "hi": "रुकिए", "ja": "保管"],
        "sell":  ["en": "SELL", "te": "అమ్మండి", "hi": "बेचें", "ja": "販売"],
        "advice_hold": ["en": "Batch is {d} days from dry. Prices rising. Hold.",
                        "te": "పంట ఆరడానికి ఇంకా {d} రోజులు. ధరలు పెరుగుతున్నాయి. ఆగండి.",
                        "hi": "फसल सूखने में {d} दिन बाकी। दाम बढ़ रहे हैं। रुकिए।",
                        "ja": "乾燥完了まであと{d}日。価格は上昇中。今は保管。"],
        "advice_hold_soon": ["en": "Batch is almost dry. Prices rising. Hold.",
                             "te": "పంట దాదాపు ఆరిపోయింది. ధరలు పెరుగుతున్నాయి. ఆగండి.",
                             "hi": "फसल लगभग सूख गई है। दाम बढ़ रहे हैं। रुकिए।",
                             "ja": "まもなく乾燥完了。価格は上昇中。今は保管。"],
        "advice_sell": ["en": "Batch is dry and price is at a 30-day high. Sell now.",
                        "te": "పంట ఆరిపోయింది, ధర 30 రోజుల గరిష్ఠంలో ఉంది. ఇప్పుడే అమ్మండి.",
                        "hi": "फसल सूख गई है और दाम 30 दिन में सबसे ऊँचा है। अभी बेचें।",
                        "ja": "乾燥完了、価格は30日間の最高値。今すぐ販売。"],
        "worth":   ["en": "Your batch is worth about", "te": "మీ పంట విలువ సుమారు", "hi": "आपकी फसल की कीमत लगभग", "ja": "このロットの価値は約"],
        "undried": ["en": "Dried on open ground, sun-bleached: about {v}", "te": "నేలపై ఆరబెట్టి, రంగు పోయిన మిరప: సుమారు {v}", "hi": "खुली ज़मीन पर सुखाई, रंग उड़ी मिर्च: लगभग {v}", "ja": "地面で天日干し（色あせ）の場合：約{v}"],

        // Record
        "my_season":    ["en": "My season", "te": "నా సీజన్", "hi": "मेरा सीज़न", "ja": "今シーズン"],
        "batches":      ["en": "Batches this season", "te": "ఈ సీజన్ బ్యాచ్‌లు", "hi": "इस सीज़न के बैच", "ja": "今季のロット"],
        "readings":     ["en": "Readings recorded", "te": "నమోదైన రీడింగులు", "hi": "दर्ज रीडिंग", "ja": "記録した測定値"],
        "photos":       ["en": "Photos graded", "te": "గ్రేడ్ చేసిన ఫోటోలు", "hi": "ग्रेड की गई तस्वीरें", "ja": "判定した写真"],
        "past_batches": ["en": "Past batches", "te": "గత బ్యాచ్‌లు", "hi": "पिछले बैच", "ja": "過去のロット"],
        "days_to_dry":  ["en": "{d} days to dry", "te": "{d} రోజుల్లో ఆరింది", "hi": "{d} दिन में सूखा", "ja": "乾燥 {d}日"],
        "sold_at":      ["en": "Sold at {v}", "te": "{v}కి అమ్మారు", "hi": "{v} पर बिका", "ja": "{v}で販売"],
        "unlocks_title": ["en": "What this record unlocks", "te": "ఈ రికార్డు వల్ల ఏమి లభిస్తుంది", "hi": "इस रिकॉर्ड से क्या मिलता है", "ja": "この記録でできること"],
        "unlock_buyers": ["en": "Buyers see a quality certificate", "te": "కొనుగోలుదారులకు నాణ్యత సర్టిఫికెట్", "hi": "खरीदारों को गुणवत्ता प्रमाणपत्र", "ja": "買い手に品質証明書"],
        "unlock_banks":  ["en": "Banks see a harvest history", "te": "బ్యాంకులకు పంట చరిత్ర", "hi": "बैंकों को फसल का इतिहास", "ja": "銀行に収穫履歴"],
        "unlock_advice": ["en": "Next season's advice improves", "te": "వచ్చే సీజన్ సలహా మెరుగవుతుంది", "hi": "अगले सीज़न की सलाह बेहतर", "ja": "来季のアドバイスが向上"],
        "share_cert":   ["en": "Share quality certificate", "te": "నాణ్యత సర్టిఫికెట్ పంపండి", "hi": "गुणवत्ता प्रमाणपत्र भेजें", "ja": "品質証明書を共有"],
        "cert_title":   ["en": "Quality certificate", "te": "నాణ్యత సర్టిఫికెట్", "hi": "गुणवत्ता प्रमाणपत्र", "ja": "品質証明書"],
        "cert_batch":   ["en": "Batch", "te": "బ్యాచ్", "hi": "बैच", "ja": "ロット"],
        "cert_moisture": ["en": "Moisture at storage", "te": "నిల్వ సమయంలో తేమ", "hi": "भंडारण के समय नमी", "ja": "保管時の水分"],
        "cert_drying":  ["en": "Drying", "te": "ఆరబెట్టడం", "hi": "सुखाई", "ja": "乾燥期間"],
        "cert_stored":  ["en": "Stored on", "te": "నిల్వ చేసిన తేదీ", "hi": "भंडारण की तारीख", "ja": "保管開始日"],
        "cert_footer":  ["en": "Recorded automatically by Harvest Protector Unit B",
                         "te": "హార్వెస్ట్ ప్రొటెక్టర్ యూనిట్ B స్వయంగా నమోదు చేసింది",
                         "hi": "हार्वेस्ट प्रोटेक्टर यूनिट B द्वारा अपने आप दर्ज",
                         "ja": "ハーベスト・プロテクター ユニットBが自動で記録"],

        // Values
        "Chilli": ["en": "Chilli", "te": "మిరప", "hi": "मिर्च", "ja": "唐辛子"],
        "Low":    ["en": "Low", "te": "తక్కువ", "hi": "कम", "ja": "低"],

        // Alerts and notifications
        "alert_rain_title": ["en": "Rain coming", "te": "వర్షం వస్తోంది", "hi": "बारिश आ रही है", "ja": "雨が近づいています"],
        "alert_rain_body":  ["en": "Rain in 40 minutes. Vents on Units A and C are closing.",
                             "te": "40 నిమిషాల్లో వర్షం. యూనిట్ A, C వెంట్లు మూసుకుంటున్నాయి.",
                             "hi": "40 मिनट में बारिश। यूनिट A और C के वेंट बंद हो रहे हैं।",
                             "ja": "40分後に雨。ユニットAとCの通気口を閉じています。"],
        "alert_almostDry_title": ["en": "Almost dry", "te": "దాదాపు ఆరింది", "hi": "लगभग सूखी", "ja": "まもなく乾燥完了"],
        "alert_almostDry_body":  ["en": "Unit A chilli is almost dry: 11.2%. Ready in about 12 hours.",
                                  "te": "యూనిట్ A మిరప దాదాపు ఆరిపోయింది: 11.2%. సుమారు 12 గంటల్లో సిద్ధం.",
                                  "hi": "यूनिट A की मिर्च लगभग सूख गई है: 11.2%। लगभग 12 घंटे में तैयार।",
                                  "ja": "ユニットAの唐辛子はまもなく乾燥完了：11.2%。約12時間で完了。"],
        "alert_priceJump_title": ["en": "Price up", "te": "ధర పెరిగింది", "hi": "दाम बढ़ा", "ja": "価格上昇"],
        "alert_priceJump_body":  ["en": "Guntur yard is paying ₹15,600 per 100 kg, 20% above last week.",
                                  "te": "గుంటూరు యార్డ్‌లో 100 కిలోలకు ₹15,600, గత వారం కంటే 20% ఎక్కువ.",
                                  "hi": "गुंटूर मंडी में ₹15,600 प्रति 100 किलो, पिछले हफ़्ते से 20% ज़्यादा।",
                                  "ja": "グントゥール市場で100kgあたり₹15,600、先週より20%高。"],
        "alert_dryingStarted_title": ["en": "Drying started", "te": "ఆరబెట్టడం మొదలైంది", "hi": "सुखाई शुरू", "ja": "乾燥開始"],
        "alert_dryingStarted_body":  ["en": "Unit A: 1,000 kg chilli loaded. Vents open.",
                                      "te": "యూనిట్ A: 1,000 కిలోల మిరప లోడ్ అయింది. వెంట్లు తెరిచి ఉన్నాయి.",
                                      "hi": "यूनिट A: 1,000 किलो मिर्च रखी गई। वेंट खुले हैं।",
                                      "ja": "ユニットA：唐辛子1,000kgを投入。通気口：開。"],
        "alert_storageCheck_title": ["en": "Storage check", "te": "నిల్వ తనిఖీ", "hi": "भंडारण जाँच", "ja": "保管チェック"],
        "alert_storageCheck_body":  ["en": "Unit B: humidity 58%, mould risk low.",
                                     "te": "యూనిట్ B: తేమ 58%, బూజు ప్రమాదం తక్కువ.",
                                     "hi": "यूनिट B: नमी 58%, फफूंद का खतरा कम।",
                                     "ja": "ユニットB：湿度58%、カビのリスク低。"],

        // Dashboard and tabs
        "tab_units":   ["en": "Units", "te": "యూనిట్లు", "hi": "यूनिट", "ja": "ユニット"],
        "tab_network": ["en": "Network", "te": "నెట్‌వర్క్", "hi": "नेटवर्क", "ja": "ネットワーク"],
        "crop_protected": ["en": "crop protected", "te": "పంట సురక్షితం", "hi": "फसल सुरक्षित", "ja": "保護中の作物"],
        "units_n":   ["en": "{n} units", "te": "{n} యూనిట్లు", "hi": "{n} यूनिट", "ja": "{n}ユニット"],
        "today":     ["en": "Today", "te": "ఈరోజు", "hi": "आज", "ja": "今日"],
        "see_units": ["en": "See my units", "te": "నా యూనిట్లు చూడండి", "hi": "मेरी यूनिट देखें", "ja": "ユニットを見る"],

        // Network: sell side
        "buy_tab":        ["en": "Buy", "te": "కొనుగోలు", "hi": "खरीदें", "ja": "購入"],
        "nearby_markets": ["en": "Nearby markets", "te": "దగ్గరి మార్కెట్లు", "hi": "नज़दीकी मंडियाँ", "ja": "近くの市場"],
        "market_guntur":   ["en": "Guntur", "te": "గుంటూరు", "hi": "गुंटूर", "ja": "グントゥール"],
        "market_khammam":  ["en": "Khammam", "te": "ఖమ్మం", "hi": "खम्मम", "ja": "カンマム"],
        "market_warangal": ["en": "Warangal", "te": "వరంగల్", "hi": "वारंगल", "ja": "ワランガル"],
        "km":             ["en": "{n} km", "te": "{n} కి.మీ.", "hi": "{n} किमी", "ja": "{n} km"],
        "expected_next_week": ["en": "Expected next week: {v}", "te": "వచ్చే వారం అంచనా: {v}", "hi": "अगले हफ़्ते का अनुमान: {v}", "ja": "来週の予想：{v}"],
        "price_alert":   ["en": "Price alert", "te": "ధర హెచ్చరిక", "hi": "दाम अलर्ट", "ja": "価格アラート"],
        "notify_at":     ["en": "Notify me at {v}", "te": "{v} వచ్చినప్పుడు తెలియజేయండి", "hi": "{v} होने पर बताएं", "ja": "{v}になったら通知"],
        "alert_set":     ["en": "Alert set at {v}", "te": "{v} వద్ద హెచ్చరిక సెట్ అయింది", "hi": "{v} पर अलर्ट सेट है", "ja": "{v}でアラート設定済み"],
        "alert_reached": ["en": "Target reached: {v}", "te": "లక్ష్య ధర వచ్చింది: {v}", "hi": "लक्ष्य दाम मिल गया: {v}", "ja": "目標価格に到達：{v}"],
        "remove":        ["en": "Remove", "te": "తీసేయండి", "hi": "हटाएं", "ja": "解除"],
        "alert_priceTarget_title": ["en": "Price alert", "te": "ధర హెచ్చరిక", "hi": "दाम अलर्ट", "ja": "価格アラート"],
        "alert_priceTarget_body":  ["en": "Guntur yard has reached {v} per 100 kg. Your target. Sell now.",
                                    "te": "గుంటూరు యార్డ్‌లో ధర 100 కిలోలకు {v}కి చేరింది. మీ లక్ష్య ధర ఇదే. ఇప్పుడే అమ్మండి.",
                                    "hi": "गुंटूर मंडी में दाम {v} प्रति 100 किलो हो गया। यही आपका लक्ष्य था। अभी बेचें।",
                                    "ja": "グントゥール市場が100kgあたり{v}に到達。目標価格です。今すぐ販売。"],

        // Network: buy side
        "buy_seeds":  ["en": "Seeds", "te": "విత్తనాలు", "hi": "बीज", "ja": "種子"],
        "buy_fert":   ["en": "Fertilisers", "te": "ఎరువులు", "hi": "खाद", "ja": "肥料"],
        "buy_expert": ["en": "Ask an expert", "te": "నిపుణుడిని అడగండి", "hi": "विशेषज्ञ से पूछें", "ja": "専門家に相談"],
        "item_seed_hybrid":   ["en": "Hybrid chilli seed", "te": "హైబ్రిడ్ మిరప విత్తనం", "hi": "हाइब्रिड मिर्च बीज", "ja": "ハイブリッド唐辛子の種"],
        "item_seed_hybrid_d": ["en": "10 g pack", "te": "10 గ్రా. ప్యాకెట్", "hi": "10 ग्राम पैकेट", "ja": "10g入り"],
        "item_seedlings":     ["en": "Chilli seedlings", "te": "మిరప నారు", "hi": "मिर्च की पौध", "ja": "唐辛子の苗"],
        "item_seedlings_d":   ["en": "Tray of 98", "te": "98 మొక్కల ట్రే", "hi": "98 पौधों की ट्रे", "ja": "98本トレー"],
        "item_npk":           ["en": "NPK 19:19:19", "te": "NPK 19:19:19", "hi": "NPK 19:19:19", "ja": "NPK 19:19:19"],
        "item_npk_d":         ["en": "25 kg bag", "te": "25 కిలోల బస్తా", "hi": "25 किलो बोरी", "ja": "25kg袋"],
        "item_neem":          ["en": "Neem cake", "te": "వేప పిండి", "hi": "नीम खली", "ja": "ニームケーキ"],
        "item_neem_d":        ["en": "50 kg bag", "te": "50 కిలోల బస్తా", "hi": "50 किलो बोरी", "ja": "50kg袋"],
        "item_agro":          ["en": "Chilli crop expert", "te": "మిరప పంట నిపుణుడు", "hi": "मिर्च फसल विशेषज्ञ", "ja": "唐辛子栽培の専門家"],
        "item_agro_d":        ["en": "Calls you back within 2 hours", "te": "2 గంటల్లో తిరిగి కాల్ చేస్తారు", "hi": "2 घंटे में कॉल वापस", "ja": "2時間以内に折り返し電話"],
        "item_photo":         ["en": "Send a photo of the problem", "te": "సమస్య ఫోటో పంపండి", "hi": "समस्या की फोटो भेजें", "ja": "症状の写真を送る"],
        "item_photo_d":       ["en": "Answer the same day", "te": "అదే రోజు సమాధానం", "hi": "उसी दिन जवाब", "ja": "当日中に回答"],
        "order":     ["en": "Order", "te": "ఆర్డర్", "hi": "ऑर्डर करें", "ja": "注文"],
        "request":   ["en": "Request", "te": "అడగండి", "hi": "अनुरोध करें", "ja": "依頼"],
        "requested": ["en": "Requested", "te": "అభ్యర్థించారు", "hi": "अनुरोध भेजा", "ja": "依頼済み"],

        // Voice
        "hold_to_speak": ["en": "Hold to speak", "te": "నొక్కి పట్టుకుని మాట్లాడండి", "hi": "दबाकर बोलें", "ja": "押して話す"],
        "listening":     ["en": "Listening…", "te": "వింటున్నాను…", "hi": "सुन रहा हूँ…", "ja": "聞いています…"],
        "q_crop": ["en": "How is my crop?", "te": "నా పంట ఎలా ఉంది?", "hi": "मेरी फसल कैसी है?", "ja": "作物の状態は？"],
        "q_sell": ["en": "When should I sell?", "te": "ఎప్పుడు అమ్మాలి?", "hi": "कब बेचूँ?", "ja": "いつ売ればいい？"],
        "q_rain": ["en": "Is rain coming?", "te": "వర్షం వస్తుందా?", "hi": "क्या बारिश आएगी?", "ja": "雨は降りますか？"],
        "read_farm": ["en": "Read my farm aloud", "te": "నా పొలం వివరాలు చదివి వినిపించు", "hi": "मेरे खेत का हाल सुनाएँ", "ja": "農場の状況を読み上げる"],
        "ans_crop": ["en": "{crop} in Unit A is at {m} percent moisture, {d} days from dry. All {n} units are safe.",
                     "te": "యూనిట్ Aలో {crop} తేమ {m} శాతం. ఆరడానికి ఇంకా {d} రోజులు. మొత్తం {n} యూనిట్లు సురక్షితం.",
                     "hi": "यूनिट A में {crop} की नमी {m} प्रतिशत है। सूखने में {d} दिन बाकी। सभी {n} यूनिट सुरक्षित हैं।",
                     "ja": "ユニットAの{crop}は水分{m}パーセント。乾燥完了まであと{d}日。{n}ユニットすべて安全です。"],
        "ans_crop_soon": ["en": "{crop} in Unit A is at {m} percent moisture, almost dry. All {n} units are safe.",
                          "te": "యూనిట్ Aలో {crop} తేమ {m} శాతం, దాదాపు ఆరిపోయింది. మొత్తం {n} యూనిట్లు సురక్షితం.",
                          "hi": "यूनिट A में {crop} की नमी {m} प्रतिशत है, लगभग सूख गई है। सभी {n} यूनिट सुरक्षित हैं।",
                          "ja": "ユニットAの{crop}は水分{m}パーセント、まもなく乾燥完了。{n}ユニットすべて安全です。"],
        "ans_crop_dry": ["en": "{crop} in Unit A is dry and ready. All {n} units are safe.",
                         "te": "యూనిట్ Aలో {crop} ఆరిపోయింది, సిద్ధంగా ఉంది. మొత్తం {n} యూనిట్లు సురక్షితం.",
                         "hi": "यूनिट A में {crop} सूख गई है और तैयार है। सभी {n} यूनिट सुरक्षित हैं।",
                         "ja": "ユニットAの{crop}は乾燥完了です。{n}ユニットすべて安全です。"],
        "ans_worth": ["en": "Your batch is worth about {v}.", "te": "మీ పంట విలువ సుమారు {v}.", "hi": "आपकी फसल की कीमत लगभग {v} है।", "ja": "このロットの価値は約{v}です。"],
        "ans_no_rain": ["en": "No rain expected today. Drying continues.", "te": "ఈరోజు వర్షం సూచన లేదు. ఆరబెట్టడం కొనసాగుతోంది.", "hi": "आज बारिश की संभावना नहीं है। सुखाई जारी है।", "ja": "今日は雨の予報はありません。乾燥を続けています。"],
        "ans_rain": ["en": "Rain in {n} minutes. I have closed the vents.", "te": "{n} నిమిషాల్లో వర్షం. వెంట్లు మూసేశాను.", "hi": "{n} मिनट में बारिश। मैंने वेंट बंद कर दिए हैं।", "ja": "{n}分後に雨が降ります。通気口は閉じました。"],
        "rupees_spoken": ["en": "rupees ", "te": "రూపాయలు ", "hi": "रुपये ", "ja": "ルピー "],

        // Why
        "why":          ["en": "Why", "te": "ఎందుకంటే", "hi": "क्यों", "ja": "理由"],
        "why_days":     ["en": "{d} days from dry", "te": "ఆరడానికి ఇంకా {d} రోజులు", "hi": "सूखने में {d} दिन बाकी", "ja": "乾燥完了まであと{d}日"],
        "why_almost":   ["en": "Almost dry", "te": "దాదాపు ఆరింది", "hi": "लगभग सूखी", "ja": "まもなく乾燥完了"],
        "why_dry":      ["en": "Batch is dry", "te": "పంట ఆరిపోయింది", "hi": "फसल सूख गई है", "ja": "乾燥完了"],
        "why_price_up": ["en": "Price up {p}% this week", "te": "ఈ వారం ధర {p}% పెరిగింది", "hi": "इस हफ़्ते दाम {p}% बढ़ा", "ja": "今週の価格は{p}%上昇"],
        "why_high":     ["en": "Price at a 30-day high", "te": "ధర 30 రోజుల గరిష్ఠంలో ఉంది", "hi": "दाम 30 दिन में सबसे ऊँचा", "ja": "価格は30日間の最高値"],

        // Hub
        "my_farm":   ["en": "My farm", "te": "నా పొలం", "hi": "मेरा खेत", "ja": "自分の農場"],
        "hub":       ["en": "Hub", "te": "హబ్", "hi": "हब", "ja": "ハブ"],
        "hub_title": ["en": "Mamori Hub · {n} units", "te": "మామోరి హబ్ · {n} యూనిట్లు", "hi": "मामोरी हब · {n} यूनिट", "ja": "Mamoriハブ · {n}ユニット"],
        "hub_stored": ["en": "stored of {c} t", "te": "{c} టన్నులలో నిల్వ", "hi": "{c} टन में से भंडारित", "ja": "保管中（容量{c}t）"],
        "hub_fees":  ["en": "fees this season", "te": "ఈ సీజన్ ఫీజులు", "hi": "इस सीज़न की फीस", "ja": "今季の利用料"],
        "hub_farmers": ["en": "{n} farmers · ₹700 per 100 kg dried, nothing upfront",
                        "te": "{n} మంది రైతులు · 100 కిలోలకు ₹700, ముందస్తు చెల్లింపు లేదు",
                        "hi": "{n} किसान · ₹700 प्रति 100 किलो, कोई अग्रिम नहीं",
                        "ja": "農家{n}戸 · 100kgあたり₹700、初期費用なし"],
        "hub_empty": ["en": "Empty", "te": "ఖాళీ", "hi": "खाली", "ja": "空き"],
        "bags_of":   ["en": "{n} of {c} bags", "te": "{c}లో {n} బస్తాలు", "hi": "{c} में से {n} बोरियाँ", "ja": "{c}袋中 {n}袋"],

        // Mamori Eye field card
        "field_view": ["en": "Field view", "te": "పొలం వీక్షణ", "hi": "खेत का दृश्य", "ja": "圃場ビュー"],
        "addon":      ["en": "Mamori Eye add-on", "te": "మామోరి ఐ యాడ్-ఆన్", "hi": "मामोरी आई ऐड-ऑन", "ja": "Mamori Eye アドオン"],
        "field_eff":  ["en": "Field 2: work efficiency {p}%", "te": "పొలం 2: పని సామర్థ్యం {p}%", "hi": "खेत 2: कार्य दक्षता {p}%", "ja": "圃場2：作業効率 {p}%"],
        "field_missed": ["en": "Tilling missed the north edge. One more pass recommended.",
                         "te": "ఉత్తర అంచున దున్నడం మిగిలిపోయింది. మరోసారి దున్నమని సూచన.",
                         "hi": "उत्तरी किनारे की जुताई छूट गई। एक और चक्कर की सलाह।",
                         "ja": "北側の端が未耕起です。もう一度の作業をおすすめします。"],
        "soil_moisture": ["en": "Soil moisture", "te": "నేల తేమ", "hi": "मिट्टी की नमी", "ja": "土壌水分"],

        // Buyer network, crops, next season
        "sell_via":   ["en": "Sell through Mamori buyers", "te": "మామోరి కొనుగోలుదారులకు అమ్మండి", "hi": "मामोरी खरीदारों को बेचें", "ja": "Mamoriの買い手に販売"],
        "commission": ["en": "1% commission: {v}", "te": "1% కమీషన్: {v}", "hi": "1% कमीशन: {v}", "ja": "手数料1%：{v}"],
        "offer_sent": ["en": "Offer sent to buyers", "te": "కొనుగోలుదారులకు ఆఫర్ పంపాం", "hi": "खरीदारों को प्रस्ताव भेजा गया", "ja": "買い手にオファーを送信しました"],
        "Turmeric":   ["en": "Turmeric", "te": "పసుపు", "hi": "हल्दी", "ja": "ウコン"],
        "next_season": ["en": "Next season's advice", "te": "వచ్చే సీజన్ సలహా", "hi": "अगले सीज़न की सलाह", "ja": "来季へのアドバイス"],
        "next_season_body": ["en": "Batch 1 took 15 days and graded B. Load the first batch in thinner layers.",
                             "te": "బ్యాచ్ 1 ఆరడానికి 15 రోజులు పట్టింది, గ్రేడ్ B వచ్చింది. మొదటి బ్యాచ్‌ను పలుచని పొరలుగా పరచండి.",
                             "hi": "बैच 1 को 15 दिन लगे और ग्रेड B मिला। पहला बैच पतली परतों में फैलाएँ।",
                             "ja": "ロット1は15日かかり等級Bでした。最初のロットは薄く広げてください。"],

        // Voice assistant, by screen
        "q_farm":   ["en": "How is my farm?", "te": "నా పొలం ఎలా ఉంది?", "hi": "मेरा खेत कैसा है?", "ja": "農場の状況は？"],
        "q_unit":   ["en": "How is this unit?", "te": "ఈ యూనిట్ ఎలా ఉంది?", "hi": "यह यूनिट कैसी है?", "ja": "このユニットの状態は？"],
        "q_season": ["en": "How was my season?", "te": "నా సీజన్ ఎలా సాగింది?", "hi": "मेरा सीज़न कैसा रहा?", "ja": "今シーズンはどうでしたか？"],
        "ans_unit": ["en": "Unit {id}, {crop}: moisture {m} percent. {status}. {vent}.",
                     "te": "యూనిట్ {id}, {crop}: తేమ {m} శాతం. {status}. {vent}.",
                     "hi": "यूनिट {id}, {crop}: नमी {m} प्रतिशत। {status}। {vent}।",
                     "ja": "ユニット{id}、{crop}：水分{m}パーセント。{status}。{vent}。"],
        "ans_unit_tip": ["en": "The bottom tray is the wettest.", "te": "కింది ట్రేలో తేమ ఎక్కువగా ఉంది.", "hi": "सबसे नीचे की ट्रे सबसे गीली है।", "ja": "一番下のトレーが最も湿っています。"],
        "ans_record": ["en": "This season: {b} batches and {r} readings recorded. Your quality certificate is ready to share.",
                       "te": "ఈ సీజన్‌లో {b} బ్యాచ్‌లు, {r} రీడింగులు నమోదయ్యాయి. మీ నాణ్యత సర్టిఫికెట్ పంపడానికి సిద్ధంగా ఉంది.",
                       "hi": "इस सीज़न में {b} बैच और {r} रीडिंग दर्ज हुईं। आपका गुणवत्ता प्रमाणपत्र भेजने के लिए तैयार है।",
                       "ja": "今季は{b}ロット、{r}件の測定値を記録しました。品質証明書を共有できます。"],

        // Weather
        "weather_today": ["en": "Weather today", "te": "ఈరోజు వాతావరణం", "hi": "आज का मौसम", "ja": "今日の天気"],
        "rain_chance":   ["en": "Rain {p}%", "te": "వర్షం {p}%", "hi": "बारिश {p}%", "ja": "降水 {p}%"],
        "now":           ["en": "Now", "te": "ఇప్పుడు", "hi": "अभी", "ja": "現在"],
        "good_drying":   ["en": "Good drying weather", "te": "ఆరబెట్టడానికి అనుకూలం", "hi": "सुखाने के लिए अच्छा मौसम", "ja": "乾燥に適した天気"],
        "inside_a":      ["en": "inside Unit A", "te": "యూనిట్ A లోపల", "hi": "यूनिट A के अंदर", "ja": "ユニットA内部"],

        // Inside a unit
        "trays":    ["en": "Trays inside", "te": "లోపలి ట్రేలు", "hi": "अंदर की ट्रे", "ja": "内部のトレー"],
        "tray_n":   ["en": "Tray {n}", "te": "ట్రే {n}", "hi": "ट्रे {n}", "ja": "トレー{n}"],
        "top":      ["en": "top", "te": "పైన", "hi": "ऊपर", "ja": "上段"],
        "bottom":   ["en": "bottom", "te": "కింద", "hi": "नीचे", "ja": "下段"],
        "wettest":  ["en": "Wettest", "te": "ఎక్కువ తేమ", "hi": "सबसे गीली", "ja": "最も湿潤"],
        "tray_tip": ["en": "Lower trays dry slower. Swap tray 1 and tray 4 tomorrow.",
                     "te": "కింది ట్రేలు నెమ్మదిగా ఆరతాయి. రేపు ట్రే 1, ట్రే 4 మార్చండి.",
                     "hi": "नीचे की ट्रे धीरे सूखती हैं। कल ट्रे 1 और ट्रे 4 बदलें।",
                     "ja": "下段は乾燥が遅めです。明日トレー1と4を入れ替えてください。"],
        "tap_tray": ["en": "Tap a tray for temperature and humidity", "te": "ఉష్ణోగ్రత, తేమ కోసం ట్రేను నొక్కండి", "hi": "तापमान और नमी के लिए ट्रे पर टैप करें", "ja": "トレーをタップすると温度と湿度を表示"],
        "live":     ["en": "LIVE", "te": "లైవ్", "hi": "लाइव", "ja": "ライブ"],
        "show_grading": ["en": "Show grading", "te": "గ్రేడింగ్ చూపించు", "hi": "ग्रेडिंग दिखाएँ", "ja": "判定を表示"],
        "hide_grading": ["en": "Hide grading", "te": "గ్రేడింగ్ దాచు", "hi": "ग्रेडिंग छिपाएँ", "ja": "判定を隠す"],
        "fan":      ["en": "Solar fan", "te": "సోలార్ ఫ్యాన్", "hi": "सोलर पंखा", "ja": "ソーラーファン"],
        "on":       ["en": "On", "te": "ఆన్", "hi": "चालू", "ja": "稼働中"],
        "off":      ["en": "Off", "te": "ఆఫ్", "hi": "बंद", "ja": "停止"],
        "battery":  ["en": "Solar battery", "te": "సోలార్ బ్యాటరీ", "hi": "सोलर बैटरी", "ja": "ソーラー電池"],
        "days_faster": ["en": "{d} days faster", "te": "{d} రోజులు ముందుగా", "hi": "{d} दिन जल्दी", "ja": "{d}日早い"],
        "tap_unit": ["en": "Tap a unit", "te": "యూనిట్‌ను నొక్కండి", "hi": "किसी यूनिट पर टैप करें", "ja": "ユニットをタップ"],
        "cert_id":  ["en": "Certificate ID", "te": "సర్టిఫికెట్ ఐడి", "hi": "प्रमाणपत्र आईडी", "ja": "証明書ID"],

        // Voice assistant: more questions, by screen
        "q_markets": ["en": "Where should I sell?", "te": "ఎక్కడ అమ్మాలి?", "hi": "कहाँ बेचूँ?", "ja": "どこで売ればいい？"],
        "q_trays":   ["en": "Which tray is wettest?", "te": "ఏ ట్రేలో తేమ ఎక్కువ?", "hi": "कौन सी ट्रे सबसे गीली है?", "ja": "一番湿っているトレーは？"],
        "q_hub":     ["en": "How is the hub?", "te": "హబ్ ఎలా ఉంది?", "hi": "हब कैसा है?", "ja": "ハブの状況は？"],
        "ans_markets": ["en": "Guntur pays the most today: {v} per 100 kilos, {k} kilometres away. Khammam pays {v2}.",
                        "te": "ఈరోజు గుంటూరులో ఎక్కువ ధర: 100 కిలోలకు {v}, {k} కిలోమీటర్ల దూరం. ఖమ్మంలో {v2}.",
                        "hi": "आज गुंटूर सबसे ज़्यादा दे रहा है: 100 किलो के {v}, {k} किलोमीटर दूर। खम्मम में {v2}।",
                        "ja": "今日はグントゥールが最高値：100キロあたり{v}、{k}キロ先です。カンマムは{v2}。"],
        "ans_trays": ["en": "Tray {w} is the wettest at {m} percent, {d} points above the top tray. Swap them tomorrow.",
                      "te": "ట్రే {w}లో తేమ ఎక్కువ: {m} శాతం, పై ట్రే కంటే {d} ఎక్కువ. రేపు వాటిని మార్చండి.",
                      "hi": "ट्रे {w} सबसे गीली है: {m} प्रतिशत, ऊपर की ट्रे से {d} ज़्यादा। कल इन्हें बदल दें।",
                      "ja": "トレー{w}が最も湿っていて{m}パーセント、上段より{d}ポイント高いです。明日入れ替えてください。"],
        "ans_trays_even": ["en": "All trays are even at about {m} percent. Nothing to do.",
                           "te": "అన్ని ట్రేలు సుమారు {m} శాతం వద్ద సమానంగా ఉన్నాయి. ఏమీ చేయనవసరం లేదు.",
                           "hi": "सभी ट्रे लगभग {m} प्रतिशत पर बराबर हैं। कुछ करने की ज़रूरत नहीं।",
                           "ja": "全トレーが約{m}パーセントで均一です。対応は不要です。"],
        "ans_hub": ["en": "The hub has {d} units drying and {s} storing, {t} tonnes kept safe. {r} units are ready to collect this week.",
                    "te": "హబ్‌లో {d} యూనిట్లు ఆరబెడుతున్నాయి, {s} నిల్వలో ఉన్నాయి, {t} టన్నులు సురక్షితం. ఈ వారం {r} యూనిట్లు తీసుకోవడానికి సిద్ధం.",
                    "hi": "हब में {d} यूनिट सुखा रही हैं और {s} भंडारण में हैं, {t} टन सुरक्षित। इस हफ़्ते {r} यूनिट उठाने के लिए तैयार हैं।",
                    "ja": "ハブでは{d}台が乾燥中、{s}台が保管中で、{t}トンを守っています。今週{r}台が引き取り可能です。"],
        "thinking":  ["en": "Thinking…", "te": "ఆలోచిస్తున్నాను…", "hi": "सोच रहा हूँ…", "ja": "考え中…"],
        "ask_mamori": ["en": "Ask Mamori", "te": "మామోరిని అడగండి", "hi": "मामोरी से पूछें", "ja": "Mamoriに聞く"],

        // Weather card
        "feels_like":   ["en": "Feels {t}°", "te": "అనుభూతి {t}°", "hi": "महसूस {t}°", "ja": "体感 {t}°"],
        "humidity_out": ["en": "Humidity", "te": "తేమ", "hi": "नमी", "ja": "湿度"],
        "wind":         ["en": "Wind", "te": "గాలి", "hi": "हवा", "ja": "風"],
        "sun_left":     ["en": "{h} h of sun left", "te": "ఇంకా {h} గంటల ఎండ", "hi": "{h} घंटे धूप बाकी", "ja": "日照あと{h}時間"],
        "drying_watch": ["en": "Humid air: drying slower", "te": "తేమ గాలి: నెమ్మదిగా ఆరుతుంది", "hi": "नम हवा: सुखाई धीमी", "ja": "湿度が高め：乾燥が遅い"],
        "drying_bad":   ["en": "Rain coming: vents shut", "te": "వర్షం వస్తోంది: వెంట్లు మూశాం", "hi": "बारिश आ रही है: वेंट बंद", "ja": "雨が接近：通気口を閉鎖"],
        "rain_vents":   ["en": "Vents shut on Unit {u}", "te": "యూనిట్ {u} వెంట్లు మూశాం", "hi": "यूनिट {u} के वेंट बंद", "ja": "ユニット{u}の通気口を閉鎖"],
        "outside_now":  ["en": "Outside now: {t} °C · {h}% humidity", "te": "బయట ఇప్పుడు: {t} °C · తేమ {h}%", "hi": "बाहर अभी: {t} °C · नमी {h}%", "ja": "現在の屋外：{t} °C・湿度{h}%"],
        "location_guntur": ["en": "Guntur", "te": "గుంటూరు", "hi": "गुंटूर", "ja": "グントゥール"],

        // Unit cut-away
        "unit_inside":  ["en": "Inside the unit", "te": "యూనిట్ లోపల", "hi": "यूनिट के अंदर", "ja": "ユニットの内部"],
        "legend_wet":   ["en": "Wet", "te": "తడి", "hi": "गीली", "ja": "湿"],
        "legend_drying": ["en": "Drying", "te": "ఆరుతోంది", "hi": "सूख रही", "ja": "乾燥中"],
        "legend_dry":   ["en": "Dry", "te": "ఆరింది", "hi": "सूखी", "ja": "乾燥済"],
        "airflow_on":   ["en": "Warm air rising through the trays", "te": "వేడి గాలి ట్రేల గుండా పైకి వెళ్తోంది", "hi": "गरम हवा ट्रे से ऊपर उठ रही है", "ja": "暖かい空気がトレーを上昇中"],
        "airflow_off":  ["en": "Vents shut: crop sealed from rain", "te": "వెంట్లు మూశాం: పంట వర్షం నుంచి సురక్షితం", "hi": "वेंट बंद: फसल बारिश से सुरक्षित", "ja": "通気口閉鎖：作物を雨から保護"],

        // Insights
        "insights":     ["en": "What Mamori sees", "te": "మామోరి గమనించినవి", "hi": "मामोरी क्या देख रहा है", "ja": "Mamoriの分析"],
        "ins_ahead":    ["en": "Dry in {d} days: {f} days sooner than open ground",
                         "te": "{d} రోజుల్లో ఆరుతుంది: నేలపై కంటే {f} రోజులు ముందు",
                         "hi": "{d} दिन में सूखेगी: खुली ज़मीन से {f} दिन पहले",
                         "ja": "あと{d}日で乾燥：地面より{f}日早い"],
        "ins_ready":    ["en": "Dry and ready: store it or sell it", "te": "ఆరింది, సిద్ధం: నిల్వ చేయండి లేదా అమ్మండి", "hi": "सूख गई, तैयार: भंडार करें या बेचें", "ja": "乾燥完了：保管か販売へ"],
        "ins_store":    ["en": "Stored {d} days, humidity steady at {h}%", "te": "{d} రోజులుగా నిల్వ, తేమ {h}% వద్ద స్థిరం", "hi": "{d} दिन से भंडार में, नमी {h}% पर स्थिर", "ja": "保管{d}日目、湿度{h}%で安定"],
        "ins_tray":     ["en": "Bottom tray {p} points wetter than top: swap them tomorrow",
                         "te": "కింది ట్రే పై దానికంటే {p} ఎక్కువ తడి: రేపు మార్చండి",
                         "hi": "नीचे की ट्रे ऊपर से {p} ज़्यादा गीली: कल बदलें",
                         "ja": "下段は上段より{p}ポイント湿潤：明日入れ替え"],
        "ins_mould_low": ["en": "Mould risk low: air inside is {h}% humid", "te": "బూజు ప్రమాదం తక్కువ: లోపల తేమ {h}%", "hi": "फफूंद का खतरा कम: अंदर नमी {h}%", "ja": "カビのリスク低：内部湿度{h}%"],
        "ins_mould_watch": ["en": "Humid inside ({h}%): watch for mould", "te": "లోపల తేమ ఎక్కువ ({h}%): బూజు గమనించండి", "hi": "अंदर नमी ज़्यादा ({h}%): फफूंद पर नज़र रखें", "ja": "内部湿度が高い（{h}%）：カビに注意"],
        "ins_rain":     ["en": "Rain in {n} min: vents shut, crop stays dry", "te": "{n} ని.లో వర్షం: వెంట్లు మూశాం, పంట పొడిగా ఉంటుంది", "hi": "{n} मिनट में बारिश: वेंट बंद, फसल सूखी रहेगी", "ja": "{n}分後に雨：通気口閉鎖、作物は乾いたまま"],
        "ins_sell_now": ["en": "Price at a 30-day high: sell now", "te": "ధర 30 రోజుల గరిష్ఠం: ఇప్పుడే అమ్మండి", "hi": "दाम 30 दिन के उच्चतम पर: अभी बेचें", "ja": "30日最高値：今が売り時"],
        "ins_hold":     ["en": "Guntur price up {p}% this week: hold", "te": "గుంటూరు ధర ఈ వారం {p}% పెరిగింది: ఆగండి", "hi": "गुंटूर दाम इस हफ़्ते {p}% ऊपर: रुकिए", "ja": "グントゥール価格が今週{p}%上昇：保管継続"],

        // Hub
        "hub_ready":    ["en": "{n} units ready to collect this week", "te": "ఈ వారం {n} యూనిట్లు తీసుకోవడానికి సిద్ధం", "hi": "इस हफ़्ते {n} यूनिट उठाने के लिए तैयार", "ja": "今週{n}台が引き取り可能"],
        "hub_filter_hint": ["en": "Tap a count to filter the yard", "te": "యార్డ్‌ను ఫిల్టర్ చేయడానికి సంఖ్యను నొక్కండి", "hi": "यार्ड छाँटने के लिए गिनती पर टैप करें", "ja": "数字をタップして絞り込み"],
        "days_left_short": ["en": "{d} days to dry", "te": "ఆరడానికి {d} రోజులు", "hi": "सूखने में {d} दिन", "ja": "乾燥まで{d}日"],

        // Widget
        "widget_market":    ["en": "Guntur", "te": "గుంటూరు", "hi": "गुंटूर", "ja": "グントゥール"],
        "widget_rain":      ["en": "Rain in {n} min: vents closed", "te": "{n} ని.లో వర్షం: వెంట్లు మూశాం", "hi": "{n} मिनट में बारिश: वेंट बंद", "ja": "{n}分後に雨：通気口を閉鎖"],
        "widget_sell":      ["en": "Sell now: 30-day high", "te": "ఇప్పుడే అమ్మండి: 30 రోజుల గరిష్ఠం", "hi": "अभी बेचें: 30 दिन का उच्चतम", "ja": "今すぐ販売：30日最高値"],
        "widget_hold":      ["en": "Hold: {d} days to dry", "te": "ఆగండి: ఇంకా {d} రోజులు", "hi": "रुकिए: सूखने में {d} दिन", "ja": "保管：乾燥まであと{d}日"],
        "widget_hold_soon": ["en": "Hold: almost dry", "te": "ఆగండి: దాదాపు ఆరింది", "hi": "रुकिए: लगभग सूखी", "ja": "保管：まもなく乾燥完了"]
    ]
}

/// Number formatting. Western digits and Western grouping everywhere (₹156,000),
/// to match the poster.
enum Fmt {
    static func int(_ n: Int) -> String {
        n.formatted(.number.locale(Locale(identifier: "en_US")))
    }
    static func rupees(_ n: Int) -> String { "₹" + int(n) }
    static func percent1(_ x: Double) -> String { String(format: "%.1f%%", x) }
    static func kg(_ n: Int) -> String { int(n) + " kg" }
    static func signedPercent(_ n: Int) -> String { (n >= 0 ? "+" : "") + "\(n)" }
}
