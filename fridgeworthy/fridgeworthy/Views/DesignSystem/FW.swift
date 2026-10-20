import SwiftUI
import CoreText

/// Fridgeworthy design token namespace.
/// All colors, typography, spacing, radii, and shadows live here.
enum FW {

    /// Call once at app launch to register bundled custom fonts.
    static func registerFonts() {
        if let fontURL = Bundle.main.url(forResource: "Caveat-Variable", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }

    // MARK: - Colors

    enum Color {
        static let paper = SwiftUI.Color(hex: 0xFFFCF8)
        static let ink = SwiftUI.Color(hex: 0x302B35)
        static let onboardingInk = SwiftUI.Color(hex: 0x004225)
        static let today = SwiftUI.Color(hex: 0x8B0000)
        static let muted = SwiftUI.Color(hex: 0x77717D)
        static let border = SwiftUI.Color(hex: 0xE7E0E7)
        static let lavender = SwiftUI.Color(hex: 0xEAE4F4)
        static let sky = SwiftUI.Color(hex: 0xE7EFF8)
        static let primary = SwiftUI.Color(hex: 0x756A91)
        static let maya = SwiftUI.Color(hex: 0xD996AA)
        static let theo = SwiftUI.Color(hex: 0x91B8DB)
        static let iris = SwiftUI.Color(hex: 0x97C4A1)

        // Compatibility aliases used by the existing screens while they migrate.
        static let accent = primary
        static let accent2 = SwiftUI.Color(hex: 0x9C91B5)
        static let accentDeep = SwiftUI.Color(hex: 0x574D70)
        static let ink2 = ink.opacity(0.85)
        static let ink3 = muted
        static let ink4 = ink.opacity(0.3)

        static let bg = paper
        static let bgDark = SwiftUI.Color.black
        static let card = SwiftUI.Color.white
        static let cardDark = SwiftUI.Color(hex: 0x1C1C1E)
        static let surface2 = SwiftUI.Color(hex: 0xF7F4F2)
        static let sep = border

        // Legacy warm aliases now point at the approved book-paper palette.
        static let cream1 = paper
        static let cream2 = lavender
        static let cream3 = sky

        // Child detail hero
        static let amberHero1 = SwiftUI.Color(hex: 0xFFE5A8)
        static let amberHero2 = SwiftUI.Color(hex: 0xFFC67D)
        static let amberHero3 = SwiftUI.Color(hex: 0xFFB55C)

        // Paywall gradient
        static let paywall1 = SwiftUI.Color(hex: 0xC4A8E0)
        static let paywall2 = SwiftUI.Color(hex: 0x9F7AEA)
        static let paywall3 = SwiftUI.Color(hex: 0x7C3AED)

        static let childPalette = [maya, theo, iris]

        static func childColor(at index: Int) -> SwiftUI.Color {
            let normalized = (index % childPalette.count + childPalette.count) % childPalette.count
            return childPalette[normalized]
        }

        static func childColor(id: UUID) -> SwiftUI.Color {
            let stableIndex = withUnsafeBytes(of: id.uuid) { bytes in
                bytes.reduce(0) { (result: Int, byte: UInt8) in
                    (result &* 31 &+ Int(byte)) & 0x7fffffff
                }
            }
            return childColor(at: stableIndex)
        }
    }

    // MARK: - Typography

    enum Font {
        /// Hero display — 32pt rounded, bold by default.
        static func heroDisplay(
            _ size: CGFloat = 32,
            weight: SwiftUI.Font.Weight = .bold
        ) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }

        /// Large title — 36pt bold
        static let largeTitle: SwiftUI.Font = .system(size: 36, weight: .bold, design: .default)

        /// Section title — 22-24pt bold
        static func sectionTitle(_ size: CGFloat = 22) -> SwiftUI.Font {
            .system(size: size, weight: .bold, design: .rounded)
        }

        /// Card title — 21pt bold
        static let cardTitle: SwiftUI.Font = .system(size: 21, weight: .bold, design: .default)

        /// Body — 15-17pt regular/medium
        static func body(_ size: CGFloat = 16, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }

        /// Caption — 13-14pt regular/medium
        static func caption(_ size: CGFloat = 13, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }

        /// Micro — 11-12pt semibold, uppercase eyebrows
        static func micro(_ size: CGFloat = 11) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .rounded)
        }

        static func keepsake(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .serif)
        }

        /// Stat numeric — 26pt bold
        static let statNumeric: SwiftUI.Font = .system(size: 26, weight: .bold, design: .default)

        /// Caveat handwriting font (variable weight)
        static func caveat(_ size: CGFloat) -> SwiftUI.Font {
            .custom("Caveat", size: size)
        }

        /// Caveat bold
        static func caveatBold(_ size: CGFloat) -> SwiftUI.Font {
            .custom("Caveat", size: size).weight(.bold)
        }
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let s2: CGFloat = 6
        static let s: CGFloat = 8
        static let s3: CGFloat = 10
        static let m: CGFloat = 12
        static let m2: CGFloat = 14
        static let md: CGFloat = 16
        static let m3: CGFloat = 18
        static let lg: CGFloat = 20
        static let l2: CGFloat = 24
        static let l3: CGFloat = 28
        static let xl: CGFloat = 32
    }

    // MARK: - Corner Radii

    enum Radius {
        static let thumbnail: CGFloat = 12
        static let thumbnailLg: CGFloat = 14
        static let card: CGFloat = 18
        static let cardLg: CGFloat = 24
        static let sheet: CGFloat = 28
        static let sheetLg: CGFloat = 32
        static let wallpaper: CGFloat = 28
        static let tabBar: CGFloat = 32
        static let statChip: CGFloat = 18
        static let deviceOuter: CGFloat = 52
        static let deviceScreen: CGFloat = 42

        /// Pill radius — use half the element height
        static func pill(_ height: CGFloat) -> CGFloat { height / 2 }
    }

    // MARK: - Shadows

    enum Shadow {
        static func cardSoft(_ color: SwiftUI.Color = .black) -> some ViewModifier {
            FWShadow(
                layers: [
                    (color: color.opacity(0.04), radius: 1, x: 0, y: 1),
                    (color: color.opacity(0.04), radius: 6, x: 0, y: 4),
                ]
            )
        }

        static func cardMedium(_ color: SwiftUI.Color = .black) -> some ViewModifier {
            FWShadow(
                layers: [
                    (color: color.opacity(0.06), radius: 1, x: 0, y: 1),
                    (color: color.opacity(0.08), radius: 12, x: 0, y: 8),
                ]
            )
        }

        static func cardHero(_ color: SwiftUI.Color = .black) -> some ViewModifier {
            FWShadow(
                layers: [
                    (color: color.opacity(0.04), radius: 1, x: 0, y: 1),
                    (color: color.opacity(0.06), radius: 16, x: 0, y: 12),
                ]
            )
        }

        static var ctaPurple: some ViewModifier {
            FWShadow(
                layers: [
                    (color: FW.Color.accent.opacity(0.25), radius: 2, x: 0, y: 1),
                    (color: FW.Color.accent.opacity(0.3), radius: 10, x: 0, y: 8),
                ]
            )
        }

        static var ctaDark: some ViewModifier {
            FWShadow(
                layers: [
                    (color: SwiftUI.Color.black.opacity(0.18), radius: 2, x: 0, y: 1),
                    (color: SwiftUI.Color.black.opacity(0.18), radius: 10, x: 0, y: 8),
                ]
            )
        }
    }
}

// MARK: - Color hex init

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Multi-layer shadow modifier

struct FWShadow: ViewModifier {
    let layers: [(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)]

    func body(content: Content) -> some View {
        var result = AnyView(content)
        for layer in layers {
            result = AnyView(
                result.shadow(color: layer.color, radius: layer.radius, x: layer.x, y: layer.y)
            )
        }
        return result
    }
}
