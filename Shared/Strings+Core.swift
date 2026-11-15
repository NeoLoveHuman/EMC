import Foundation

/// Extra translations (Core). Same format as L10n.table: every key needs en, te, hi, ja.
extension L10n {
    static let extraCore: [String: [String: String]] = [
        // Seeded storage alert: matches Simulation.storageHumidity (48%). Used via AlertKind.bodyKey.
        "alert_storageCheck_body_v2": ["en": "Unit B: humidity 48%, mould risk low.", "te": "యూనిట్ B: తేమ 48%, బూజు ప్రమాదం తక్కువ.", "hi": "यूनिट B: नमी 48%, फफूंद का खतरा कम।", "ja": "ユニットB：湿度48%、カビのリスク低。"],

        // Hub queue (Simulation.hubQueue / HubBooking.dayKey)
        "hub_queue_title":    ["en": "Next bookings", "te": "తదుపరి బుకింగ్‌లు", "hi": "अगली बुकिंग", "ja": "次の予約"],
        "hub_queue_today":    ["en": "Today", "te": "ఈరోజు", "hi": "आज", "ja": "今日"],
        "hub_queue_tomorrow": ["en": "Tomorrow", "te": "రేపు", "hi": "कल", "ja": "明日"],
        "hub_queue_in_days":  ["en": "In {d} days", "te": "{d} రోజుల్లో", "hi": "{d} दिन में", "ja": "{d}日後"],
        "hub_queue_row":      ["en": "{name} · {crop} · {kg} · Unit {u}", "te": "{name} · {crop} · {kg} · యూనిట్ {u}", "hi": "{name} · {crop} · {kg} · यूनिट {u}", "ja": "{name} · {crop} · {kg} · ユニット{u}"],

        // Markets (Simulation.transportCostPer100kg / netPricePer100kg)
        "transport_cost": ["en": "Transport about {v} per 100 kg", "te": "రవాణా 100 కిలోకు సుమారు {v}", "hi": "ढुलाई लगभग {v} प्रति 100 किलो", "ja": "輸送費 100kgあたり約{v}"],
        "net_price":      ["en": "{v} after transport", "te": "రవాణా తర్వాత {v}", "hi": "ढुलाई के बाद {v}", "ja": "輸送費差引後 {v}"],

        // Energy (Simulation.solarWattsNow / energyTodayWh / fanOn)
        "solar_now":    ["en": "Solar {w} W", "te": "సౌర శక్తి {w} W", "hi": "सौर {w} W", "ja": "太陽光 {w} W"],
        "energy_today": ["en": "{e} Wh today", "te": "ఈరోజు {e} Wh", "hi": "आज {e} Wh", "ja": "今日 {e} Wh"],
        "fan_on":       ["en": "Fan on", "te": "ఫ్యాన్ ఆన్", "hi": "पंखा चालू", "ja": "ファン：オン"],
        "fan_off":      ["en": "Fan off", "te": "ఫ్యాన్ ఆఫ్", "hi": "पंखा बंद", "ja": "ファン：オフ"]
    ]
}
