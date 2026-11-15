import SwiftUI
import UIKit

/// Every colour, font, radius and spacing used by the app AND the widget.
/// Restyling the product is a one-file change: edit only this file.
enum Theme {

    // MARK: - Colours
    // Every colour has a light value (unchanged from the light-only design) and a dark value.
    // `ink` is "the strongest contrast colour": black in light mode, off-white in dark mode.
    // `onDark` is "text on an ink-filled or status-filled chip": white in light mode,
    // near-black in dark mode (in dark mode those fills are bright, so their text is dark).
    // `onAccent` stays black in both modes: text on lime is always dark.
    static let background   = Color(light: 0xFFFFFF, dark: 0x12130F)
    static let surface      = Color(light: 0xF4F5F0, dark: 0x1E2019)
    static let ink          = Color(light: 0x000000, dark: 0xF2F3EC)
    static let inkMuted     = Color(light: 0x5F6368, dark: 0xA7AB9F)
    static let onDark       = Color(light: 0xFFFFFF, dark: 0x12130F)
    static let accent       = Color(light: 0xC9F03A, dark: 0xC4EA3A)   // poster lime
    static let onAccent     = Color(light: 0x000000, dark: 0x000000)
    static let ringTrack    = Color(light: 0xCDD2BF, dark: 0x474C3E)
    static let good         = Color(light: 0x1E8E3E, dark: 0x4CC46A)
    static let warn         = Color(light: 0xE37400, dark: 0xFFA33A)
    static let danger       = Color(light: 0xC5221F, dark: 0xF26B61)
    static let rain         = Color(light: 0x1A73E8, dark: 0x6AA6FF)
    static let sun          = Color(light: 0xF5A300, dark: 0xFFC53D)
    static let shadow       = Color(light: 0x000000, lightOpacity: 0.18, dark: 0x000000, darkOpacity: 0.55)
    static let clear        = Color.clear

    /// Text and icons on a photo or the camera overlay: white in both modes.
    static let onPhoto      = Color(light: 0xFFFFFF, dark: 0xFFFFFF)
    /// Lime-family accent drawn ON an ink fill (voice answer card): lime in light mode,
    /// deep olive in dark mode, where the ink fill is off-white.
    static let accentOnInk  = Color(light: 0xC9F03A, dark: 0x4E6B00)
    /// Card edge. Invisible in light mode (no change); a faint light edge in dark mode,
    /// where shadows and the surface-vs-background step are hard to see on a projector.
    static let cardEdge     = Color(light: 0xFFFFFF, lightOpacity: 0, dark: 0xFFFFFF, darkOpacity: 0.10)

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
        if moisture <= 13.5 {
            return blend(light: (0x1E8E3E, 0xE37400), dark: (0x4CC46A, 0xFFA33A), (moisture - 11.5) / 2)
        }
        return blend(light: (0xE37400, 0x1A73E8), dark: (0xFFA33A, 0x6AA6FF), (moisture - 13.5) / 21.5)
    }

    /// Humidity inside a unit. Drying chamber should be dry air; storage should stay under ~65%.
    /// PLACEHOLDER thresholds: check against the business model.
    static func insideHumidityColor(_ h: Int, drying: Bool) -> Color {
        drying ? (h <= 38 ? good : (h <= 55 ? warn : danger))
               : (h <= 62 ? good : (h <= 72 ? warn : danger))
    }
    static func outsideHumidityColor(_ h: Int) -> Color { h <= 65 ? good : (h <= 80 ? warn : danger) }

    // Weather card
    static let weatherSlot      = Color(light: 0xFFFFFF, dark: 0x2A2D24)
    static let weatherRainCard  = Color(light: 0x1A73E8, dark: 0x5E9EF5)

    // Unit cut-away diagram
    static let unitShell    = Color(light: 0xEEF3E2, dark: 0x2A2E22)
    static let unitFrame    = Color(light: 0x000000, dark: 0xC9CDBF)
    static let ground       = Color(light: 0x8D6E63, dark: 0xA1887F)
    static let airflow      = Color(light: 0xF5A300, dark: 0xFFC53D)
    static let airflowIdle  = Color(light: 0x9AA0A6, lightOpacity: 0.45, dark: 0x8E9488, darkOpacity: 0.55)
    static let scanLine     = Color(light: 0xC9F03A, lightOpacity: 0.55, dark: 0xC4EA3A, darkOpacity: 0.55)

    /// Mixes two colours in sRGB. `light` and `dark` are (from, to) hex pairs.
    private static func blend(light: (UInt32, UInt32), dark: (UInt32, UInt32), _ t: Double) -> Color {
        let k: CGFloat = CGFloat(min(1, max(0, t)))
        let l: UIColor = UIColor.mix(light.0, light.1, k)
        let d: UIColor = UIColor.mix(dark.0, dark.1, k)
        return Color(uiColor: UIColor.dynamic(light: l, dark: d))
    }

    /// Ring colour per unit on the dashboard (A, B, C, then repeats).
    static let unitRingColors: [Color] = [Color(light: 0xC9F03A, dark: 0xC4EA3A),
                                          Color(light: 0x000000, dark: 0xF2F3EC),
                                          Color(light: 0x6E8B00, dark: 0x8FB21A)]
    static func unitRingColor(_ index: Int) -> Color { unitRingColors[index % unitRingColors.count] }

    static let chartUnit    = Color(light: 0x000000, dark: 0xF2F3EC)
    static let chartGround  = Color(light: 0x9AA0A6, dark: 0x8E9488)
    static let chartPrice   = Color(light: 0x000000, dark: 0xF2F3EC)
    static let chartFill    = Color(light: 0xC9F03A, lightOpacity: 0.45, dark: 0xC4EA3A, darkOpacity: 0.30)
    static let chartGuide   = Color(light: 0x5F6368, dark: 0xA7AB9F)

    // Camera card: a photo, so the same in both modes.
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
    static let inkStrong    = Color(light: 0x3C4043, dark: 0xCDD0C5)
    /// Status card backgrounds. Light: white text on each is at least 5.5:1.
    /// Dark: brighter fills with near-black text (onDark), at least 6:1.
    static let statusSafe   = Color(light: 0x137333, dark: 0x3AAE5A)
    static let statusDanger = Color(light: 0xC5221F, dark: 0xEF675D)
    /// Unread alert row tint and its marker.
    static let unreadRow    = Color(light: 0xC9F03A, lightOpacity: 0.22, dark: 0xC4EA3A, darkOpacity: 0.16)
    static let hairline     = Color(light: 0xCDD2BF, dark: 0x34372D)

    /// Presenter override for light / dark (Demo panel). Values: "system", "light", "dark".
    static let appearanceKey: String = "mamori.appearance"

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

extension Color {
    /// Dynamic colour: `light` in light mode, `dark` in dark mode (follows the view's colour scheme).
    init(light: UInt32, dark: UInt32) {
        self.init(light: light, lightOpacity: 1, dark: dark, darkOpacity: 1)
    }

    init(light: UInt32, lightOpacity: Double, dark: UInt32, darkOpacity: Double) {
        let l: UIColor = UIColor(hex: light, alpha: CGFloat(lightOpacity))
        let d: UIColor = UIColor(hex: dark, alpha: CGFloat(darkOpacity))
        self.init(uiColor: UIColor.dynamic(light: l, dark: d))
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat) {
        let r: CGFloat = CGFloat((hex >> 16) & 0xFF) / 255
        let g: CGFloat = CGFloat((hex >> 8) & 0xFF) / 255
        let b: CGFloat = CGFloat(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor(dynamicProvider: { (traits: UITraitCollection) -> UIColor in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    /// Straight sRGB mix of two hex colours, t in 0...1.
    static func mix(_ a: UInt32, _ b: UInt32, _ t: CGFloat) -> UIColor {
        func c(_ h: UInt32, _ shift: UInt32) -> CGFloat { CGFloat((h >> shift) & 0xFF) / 255 }
        let r: CGFloat = c(a, 16) + (c(b, 16) - c(a, 16)) * t
        let g: CGFloat = c(a, 8) + (c(b, 8) - c(a, 8)) * t
        let bl: CGFloat = c(a, 0) + (c(b, 0) - c(a, 0)) * t
        return UIColor(red: r, green: g, blue: bl, alpha: 1)
    }
}

extension View {
    /// Standard rounded card used across the app.
    func card() -> some View {
        self
            .padding(Theme.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).strokeBorder(Theme.cardEdge, lineWidth: 1))
    }

    /// Same card, any fill (status card, rain weather card).
    func card(fill: Color) -> some View {
        self
            .padding(Theme.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}
