import SwiftUI

/// Every colour, font, radius and spacing used by the app AND the widget.
/// Restyling the product is a one-file change: edit only this file.
enum Theme {

    // MARK: - Colours
    static let background   = Color(hex: 0xFFFFFF)
    static let surface      = Color(hex: 0xF4F5F0)
    static let ink          = Color(hex: 0x000000)
    static let inkMuted     = Color(hex: 0x5F6368)
    static let onDark       = Color(hex: 0xFFFFFF)
    static let accent       = Color(hex: 0xC9F03A)   // poster lime
    static let onAccent     = Color(hex: 0x000000)
    static let ringTrack    = Color(hex: 0xCDD2BF)
    static let good         = Color(hex: 0x1E8E3E)
    static let warn         = Color(hex: 0xE37400)
    static let danger       = Color(hex: 0xC5221F)
    static let rain         = Color(hex: 0x1A73E8)
    static let sun          = Color(hex: 0xF5A300)
    static let shadow       = Color(hex: 0x000000, opacity: 0.18)
    static let clear        = Color.clear

    /// Colour-coded readings: green is fine, amber is watch, red is bad.
    /// PLACEHOLDER thresholds: check against the business model.
    static func outsideTempColor(_ c: Int) -> Color { c >= 37 ? danger : (c >= 33 ? warn : good) }
    static func chamberTempColor(_ c: Int) -> Color { c >= 56 ? danger : (c >= 51 ? warn : good) }
    static func rainChanceColor(_ p: Int) -> Color { p >= 60 ? danger : (p >= 30 ? warn : good) }
    /// Wet crop is blue, nearly dry is amber, dry is green.
    static func wetnessColor(_ moisture: Double) -> Color { moisture <= 12 ? good : (moisture <= 25 ? warn : rain) }

    /// Smooth version of wetnessColor, so trays one point apart still look different.
    /// ≤11.5% green → 13.5% amber → 35% blue.
    static func wetnessRamp(_ moisture: Double) -> Color {
        if moisture <= 11.5 { return good }
        if moisture <= 13.5 { return blend(0x1E8E3E, 0xE37400, (moisture - 11.5) / 2) }
        return blend(0xE37400, 0x1A73E8, (moisture - 13.5) / 21.5)
    }

    /// Humidity inside a unit. Drying chamber should be dry air; storage should stay under ~65%.
    /// PLACEHOLDER thresholds: check against the business model.
    static func insideHumidityColor(_ h: Int, drying: Bool) -> Color {
        drying ? (h <= 38 ? good : (h <= 55 ? warn : danger))
               : (h <= 62 ? good : (h <= 72 ? warn : danger))
    }
    static func outsideHumidityColor(_ h: Int) -> Color { h <= 65 ? good : (h <= 80 ? warn : danger) }

    // Weather card
    static let weatherSlot      = Color(hex: 0xFFFFFF)
    static let weatherRainCard  = Color(hex: 0x1A73E8)

    // Unit cut-away diagram
    static let unitShell    = Color(hex: 0xEEF3E2)
    static let unitFrame    = Color(hex: 0x000000)
    static let ground       = Color(hex: 0x8D6E63)
    static let airflow      = Color(hex: 0xF5A300)
    static let airflowIdle  = Color(hex: 0x9AA0A6, opacity: 0.45)
    static let scanLine     = Color(hex: 0xC9F03A, opacity: 0.55)

    private static func blend(_ a: UInt32, _ b: UInt32, _ t: Double) -> Color {
        let t = min(1, max(0, t))
        func c(_ h: UInt32, _ shift: UInt32) -> Double { Double((h >> shift) & 0xFF) / 255 }
        return Color(.sRGB,
                     red: c(a, 16) + (c(b, 16) - c(a, 16)) * t,
                     green: c(a, 8) + (c(b, 8) - c(a, 8)) * t,
                     blue: c(a, 0) + (c(b, 0) - c(a, 0)) * t,
                     opacity: 1)
    }

    /// Ring colour per unit on the dashboard (A, B, C, then repeats).
    static let unitRingColors: [Color] = [Color(hex: 0xC9F03A), Color(hex: 0x000000), Color(hex: 0x6E8B00)]
    static func unitRingColor(_ index: Int) -> Color { unitRingColors[index % unitRingColors.count] }

    static let chartUnit    = Color(hex: 0x000000)
    static let chartGround  = Color(hex: 0x9AA0A6)
    static let chartPrice   = Color(hex: 0x000000)
    static let chartFill    = Color(hex: 0xC9F03A, opacity: 0.45)
    static let chartGuide   = Color(hex: 0x5F6368)

    static let cameraPlaceholderTop    = Color(hex: 0xB3261E)
    static let cameraPlaceholderBottom = Color(hex: 0x5E0F0B)
    static let cameraOverlay           = Color(hex: 0x000000, opacity: 0.55)

    // MARK: - Fonts (sized to be readable on a projector from 5 m)
    static let heroNumber   = Font.system(size: 60, weight: .heavy, design: .rounded)
    static let bigNumber    = Font.system(size: 40, weight: .bold, design: .rounded)
    static let ringNumber   = Font.system(size: 28, weight: .heavy, design: .rounded)
    static let dashRingNumber = Font.system(size: 20, weight: .heavy, design: .rounded)
    static let detailRingNumber = Font.system(size: 48, weight: .heavy, design: .rounded)
    static let screenTitle  = Font.system(size: 34, weight: .heavy)
    static let sectionTitle = Font.system(size: 22, weight: .bold)
    static let headline     = Font.system(size: 20, weight: .semibold)
    static let body         = Font.system(size: 18, weight: .regular)
    static let label        = Font.system(size: 16, weight: .semibold)
    static let caption      = Font.system(size: 14, weight: .medium)
    static let tabLabel     = Font.system(size: 11, weight: .semibold)
    static let tabIcon      = Font.system(size: 22, weight: .semibold)
    static let weatherIcon  = Font.system(size: 46, weight: .bold)
    static let weatherTemp  = Font.system(size: 64, weight: .heavy, design: .rounded)
    static let micIcon      = Font.system(size: 22, weight: .bold)

    // Mic button docked on the tab bar
    static let micOuter: CGFloat = 68
    static let micInner: CGFloat = 56

    // Widget
    static let widgetNumber  = Font.system(size: 17, weight: .heavy, design: .rounded)
    static let widgetTitle   = Font.system(size: 15, weight: .bold)
    static let widgetBody    = Font.system(size: 13, weight: .semibold)
    static let widgetCaption = Font.system(size: 11, weight: .semibold)
    static let widgetPrice   = Font.system(size: 24, weight: .heavy, design: .rounded)
    static let lockTitle     = Font.system(size: 15, weight: .bold)
    static let lockBody      = Font.system(size: 15, weight: .semibold)
    static let lockCaption   = Font.system(size: 12, weight: .medium)

    // MARK: - Shape and spacing
    static let cardRadius: CGFloat = 22
    static let tileRadius: CGFloat = 16
    static let padding: CGFloat = 16
    static let spacing: CGFloat = 14
    static let ringLineWidth: CGFloat = 12
    static let detailRingLineWidth: CGFloat = 20
    static let widgetRingLineWidth: CGFloat = 7
    static let heroRingSize: CGFloat = 290
    static let heroRingWidth: CGFloat = 22
    static let heroRingGap: CGFloat = 6

    // MARK: - Projector polish (added 15 Nov). Additive only: nothing above changed.

    /// Secondary text that survives a washed-out projector (about 10:1 on white, vs 6:1 for inkMuted).
    static let inkStrong    = Color(hex: 0x3C4043)
    /// Status card backgrounds. White text on each is at least 5.5:1.
    static let statusSafe   = Color(hex: 0x137333)
    static let statusDanger = Color(hex: 0xC5221F)
    /// Unread alert row tint and its marker.
    static let unreadRow    = Color(hex: 0xC9F03A, opacity: 0.22)
    static let hairline     = Color(hex: 0xCDD2BF)

    /// One spacing scale: 4 · 8 · 12 · spacing (14) · padding (16).
    static let space1: CGFloat = 4
    static let space2: CGFloat = 8
    static let space3: CGFloat = 12

    /// Smallest tap target (Apple HIG).
    static let minTap: CGFloat = 44

    // Tab bar and mic
    static let tabItemHeight: CGFloat = 56
    static let micSlotWidth: CGFloat = 80
    /// How far the mic button rises above the top edge of the tab bar.
    static let micLift: CGFloat = 24
    /// Extra bottom margin for every scroll view on a tab screen. The tab bar itself is
    /// already a bottom safe-area inset; this clears the mic that sticks up above it.
    static let scrollBottomInset: CGFloat = 40
    /// Gap between the tab bar's top edge and the bottom of the voice answer bubble.
    static let voiceBubbleLift: CGFloat = 36

    // Fonts. Fixed sizes for the projector; nothing important under 15 pt.
    static let tabLabelLarge = Font.system(size: 15, weight: .semibold)
    static let small         = Font.system(size: 15, weight: .medium)
    static let smallBold     = Font.system(size: 15, weight: .bold)
    static let statusTitle   = Font.system(size: 24, weight: .heavy)
    static let badgeCount    = Font.system(size: 13, weight: .heavy, design: .rounded)
    /// Sentence fonts that grow with Dynamic Type (same size as headline / label / body at the default setting).
    static let dynHeadline   = Font.system(.title3, design: .default, weight: .semibold)
    static let dynLabel      = Font.system(.callout, design: .default, weight: .semibold)
    static let dynBody       = Font.system(.body, design: .default, weight: .regular)
    static let dynSmall      = Font.system(.subheadline, design: .default, weight: .medium)

    // Motion: one short curve everywhere, switched off by Reduce Motion.
    static let motionQuick = Animation.easeInOut(duration: 0.25)
    static let motionRing  = Animation.easeOut(duration: 0.9)
    static func motion(_ animation: Animation, reduce: Bool) -> Animation? {
        reduce ? nil : animation
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

extension View {
    /// Standard rounded card used across the app.
    func card() -> some View {
        self
            .padding(Theme.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    /// Same card, any fill (status card, rain weather card).
    func card(fill: Color) -> some View {
        self
            .padding(Theme.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}
