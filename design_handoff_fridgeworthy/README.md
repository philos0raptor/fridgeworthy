# Handoff: Fridgeworthy iOS App

## Overview

Fridgeworthy is an iOS app for parents to capture their kid's artwork and turn it into wallpapers, prints, and gifts. This handoff covers six core screens at production fidelity: SignIn, Home, Child Detail, Gallery, Style Picker, and Paywall.

## About the Design Files

The files in this bundle are **design references created in HTML** — interactive React/JSX prototypes that show the intended look, layout, and behavior. They are **not** production code to copy directly.

Your task is to **recreate these designs in the target codebase's existing environment** (SwiftUI / UIKit if native iOS; React Native / Expo if cross-platform; web React if PWA), using the codebase's established patterns, design tokens, and component libraries. If no environment exists yet, choose the framework that best fits the project's goals — native SwiftUI is recommended for the polish level shown here.

The HTML mocks include hand-drawn SVG kid-artwork and SVG wallpaper previews; in production those should be **replaced with real user-uploaded images** and **real generated wallpaper renders** from the backend.

## Fidelity

**High-fidelity (hifi).** All colors, typography, spacing, corner radii, shadows, and interaction affordances are final. Recreate pixel-perfectly using the codebase's existing libraries.

Designs target **iPhone 15 / 16 (402 × 874 logical points)** with iOS 18 chrome (Dynamic Island, status bar, home indicator). Status bar / Dynamic Island / home indicator should come from the OS — do not draw them yourself in production.

## Design Tokens

### Colors
| Token | Hex | Usage |
|---|---|---|
| `accent` | `#7C3AED` | Primary brand purple — CTAs, active states, accents |
| `accent2` | `#9F7AEA` | Lighter purple — gradient secondary |
| `accent-deep` | `#5B21B6` | Pressed states |
| `ink` | `#000000` | Primary text |
| `ink2` | `rgba(60,60,67,0.85)` | Secondary text |
| `ink3` | `rgba(60,60,67,0.6)` | Tertiary text, captions |
| `ink4` | `rgba(60,60,67,0.3)` | Quaternary, dividers |
| `bg` | `#F2F2F7` | App background (iOS system grouped) |
| `bg-dark` | `#000000` | Dark mode background |
| `card` | `#FFFFFF` | Card / list surface |
| `card-dark` | `#1C1C1E` | Dark mode card |
| `surface2` | `#F2F2F7` | Inset segmented bg |
| `sep` | `rgba(60,60,67,0.12)` | List separator |
| `cream-1` | `#FFF6E8` | SignIn warm gradient top |
| `cream-2` | `#F4ECD8` | SignIn warm gradient mid |
| `cream-3` | `#E8DCC0` | SignIn warm gradient bottom |
| `amber-hero-1` | `#FFE5A8` | Maya child-detail hero top |
| `amber-hero-2` | `#FFC67D` | mid |
| `amber-hero-3` | `#FFB55C` | bottom |
| `paywall-1` | `#C4A8E0` | Paywall gradient top |
| `paywall-2` | `#9F7AEA` | mid |
| `paywall-3` | `#7C3AED` | bottom |

### Typography
**SF Pro** (system) for everything. Both Display and Text optical sizes.
| Role | Font | Size | Weight | Tracking | Line height |
|---|---|---|---|---|---|
| Hero display | SF Pro Display | 32 | 700–800 | -0.7 to -0.9 | 1.05–1.1 |
| Large title | SF Pro Display | 36 | 700 | -0.9 | 1.1 |
| Section title | SF Pro Display | 22–24 | 700 | -0.5 to -0.6 | 1.2 |
| Card title | SF Pro Display | 21 | 700 | -0.5 | 1.2 |
| Body | SF Pro Text | 15–17 | 400–500 | -0.2 to -0.4 | 1.35–1.4 |
| Caption | SF Pro Text | 13–14 | 400–500 | -0.2 | 1.3 |
| Micro | SF Pro Text | 11–12 | 600 | 0.4 (uppercase eyebrows) | 1.3 |
| Stat numeric | SF Pro Display | 26 | 700 | -0.7 | 1 |

**Caveat** (Google Fonts) is used for handwritten accents only — kid signatures, "everywhere" tagline underline label, dates on lock screen. Do not use for body text.

### Spacing scale
4 / 6 / 8 / 10 / 12 / 14 / 16 / 18 / 20 / 24 / 28 / 32. Padding rhythm: 16px page edges, 20px for headlines, 24–28px for hero modals.

### Corner radii
| Element | Radius |
|---|---|
| Buttons (md/lg) | half-height (pill) |
| Cards / featured | 18 / 24 |
| Sheets (top corners) | 28 / 32 |
| Thumbnails | 12 / 14 |
| Chips | half-height (pill) |
| Stat chips | 18 |
| Wallpaper preview | 24–32 |
| Tab bar | 32 (pill) |
| Device frame | 52 outer / 42 screen |

### Shadows
| Token | Value |
|---|---|
| `card-soft` | `0 1px 2px rgba(0,0,0,0.04), 0 4px 12px rgba(0,0,0,0.04)` |
| `card-medium` | `0 1px 2px rgba(0,0,0,0.06), 0 8px 24px rgba(0,0,0,0.08)` |
| `card-hero` | `0 1px 2px rgba(0,0,0,0.04), 0 12px 32px rgba(0,0,0,0.06)` |
| `cta-purple` | `0 1px 3px rgba(124,58,237,0.25), 0 8px 20px rgba(124,58,237,0.3)` |
| `cta-dark` | `0 1px 3px rgba(0,0,0,0.18), 0 8px 20px rgba(0,0,0,0.18)` |
| `tabbar-glass` | `0 1px 2px rgba(0,0,0,0.04), 0 8px 24px rgba(0,0,0,0.10), inset 0 0 0 0.5px rgba(0,0,0,0.06)` |

### Liquid glass surfaces (iOS 18 style)
- Background: `rgba(255,255,255,0.78)` (light) / `rgba(120,120,128,0.28)` (dark)
- Backdrop filter: `blur(24px) saturate(180%)`
- Inset border: `inset 0 0 0 0.5px rgba(0,0,0,0.06)`

## Screens

### 1 · SignIn
**Purpose:** Land the value prop and authenticate. Apple sign-in primary.

**Layout (top to bottom):**
- Cream radial gradient bg with paper-grain noise overlay (~40% opacity).
- 28px horizontal padding, 78px top / 44px bottom.
- Brand mark row: 36px purple rounded-square logo (heart glyph) + "Fridgeworthy" 22pt SF Pro Display 700, tracking -0.5.
- Stacked deck of 3 artwork cards in center (220×270 container, cards are 200×240 white with 10px padding, rotations −7° / +4° / −2°, soft drop shadow). Yellow tape strip at top of stack.
- Each card: artwork + handwritten Caveat caption "By Maya, age 5", etc.
- Tagline: 32pt 700 "Their art, / everywhere." with purple crayon underline beneath "everywhere".
- Subhead: 16pt ink2.
- CTAs: black pill "Continue with Apple" (54px tall, with Apple logo glyph) + glass pill "Use email" (rgba white, blur 20px).
- Footer microcopy with purple Terms / Privacy links.

### 2 · Home
**Purpose:** Daily home — featured artwork and quick access to kids.

**Layout:**
- Top floating row at 60pt: 40pt avatar (white circle) on left, purple "+ New piece" pill on right.
- Greeting: "Hi, Sam" 32pt 700 + subtitle "3 kids · 47 pieces" ink3 15pt.
- Horizontal child chip rail (overflow-scrollable in production): pill chips 22pt radius, each with 28pt color circle + emoji + name. Active chip has 1.5px purple border.
- Eyebrow "FEATURED THIS WEEK" 11pt 700 letter-spaced 1.2 in accent purple.
- Featured card (24pt radius, white): 4:3.5 aspect artwork on cream gradient with floating glass caption pill "Maya, age 5" (Caveat). Card body has title "The Castle on Tuesday" 21pt, meta line, then primary "Make wallpaper" button (purple pill with wand glyph) + secondary 40pt circular share button.
- "Recent" section header (19pt 700 + purple "See all").
- Horizontal scroll of 130pt-wide thumbnail cards.
- **Bottom tab bar (`HFTabBar`):** floating 64pt pill, 16pt margin from edges/18pt from bottom. 5 tabs: Home / Gallery / [+ CTA accent circle] / Shop / Me. Liquid-glass surface.

### 3 · Child Detail
**Purpose:** All artwork from one child.

**Layout:**
- Top 360pt amber gradient hero band (`#FFE5A8 → #FFC67D → #FFB55C`) with grain overlay.
- Glass nav buttons at top-left (back) and top-right (sparkle / generate) — 40pt circles.
- Hero row at 116pt: 88pt white avatar circle with emoji (🦊), then name "Maya" 32pt 800 dark-amber `#2a1a05` and "5 years old · since Mar 2023" subtitle.
- Stat chip row at 232pt: 3 equal glass chips, each with stat number (26pt 700) + label.
- White sheet rises at 340pt with 28pt top corners.
- iOS-style segmented control "All / Wallpapers / Prints" — pill inset on inset segmented background.
- Section header "THIS WEEK" (13pt 600 ink3 uppercase) → 3-column grid of 1:1 thumbnails (14pt radius white cards).
- Repeat for "LAST WEEK".
- HFTabBar at bottom.

### 4 · Gallery
**Purpose:** All artwork chronologically across all kids.

**Layout:**
- Nav row at 60pt: back button + "All kids" filter dropdown chip.
- Large title "Gallery" 36pt 700 + subtitle.
- Scroll of month sections. Each section:
  - Header: "October" 24pt 700 + "2025" ink3 + right-aligned "7 pieces" count + purple crayon-underline SVG below the heading row.
  - 3-column thumbnail grid, 14pt radius white cards, 6pt gap.
  - Each thumbnail has a small (18pt) colored kid-emoji badge in the bottom-left corner.
- HFTabBar active="gallery".

### 5 · Style Picker
**Purpose:** Pick the wallpaper art style before generating.

**Layout:**
- Modal nav bar (60pt): purple "Cancel" with chevron + center title "Choose style" 17pt 600.
- Lock-screen preview card 180×300pt centered, 32pt radius. Live wallpaper render with Dynamic Island overlay, "Tuesday, Oct 28" weekday and "9:41" 64pt ultralight time text on top.
- Style name + subhead below preview.
- 4-column grid of style thumbnails (1:1.2 aspect, 12pt radius). Selected thumb has 2.5px purple ring + purple shadow. Each shows a corner "PRO" pill if locked. Caption gradient at bottom of each tile.
- Bottom CTA: full-width purple pill "Generate · 3 free left" with wand glyph.

### 6 · Paywall
**Purpose:** Convert to subscription.

**Layout:**
- Full-screen purple radial gradient bg `#C4A8E0 → #9F7AEA → #7C3AED` with white paper-grain noise (~25%).
- Glass close button top-right.
- Hero: 3 wallpaper preview cards in fan layout (left tilted -8°, right tilted +8°, center upright on top, 150×240pt). Yellow crown badge floats above.
- White sheet rises with 32pt top corners and -8px/32px upward shadow.
- Headline: "Unlock the / full studio." 30pt 800 centered.
- Subhead: "Every style. Unlimited wallpapers. Free shipping."
- Three feature rows, each with 24pt purple check disc + 15pt copy.
- Two plan cards (Monthly $6.99 / Yearly $3.99), Yearly is the recommended one — 2px purple border, light purple bg, "SAVE 40%" pill on top edge.
- CTA: full-width purple pill "Start 7-day free trial" 17pt 700.
- "Cancel anytime · Restore purchases" footer.

## Interactions & Behavior

### Navigation
- SignIn → Apple auth → if first run, onboarding (out of scope) → Home.
- Home: tap child chip → Child Detail. Tap featured artwork → ArtworkDetail (out of scope). Tap "Make wallpaper" → StylePicker.
- Child Detail: same artwork tap behavior. Tap sparkle nav → StylePicker.
- Gallery: tap thumbnail → ArtworkDetail. Tap "All kids" chip → filter sheet.
- StylePicker: tapping a style updates the live preview. PRO style → opens Paywall. "Generate" → generation loading → result.
- Paywall: close → previous screen. Plan tap selects. CTA → StoreKit purchase.

### Animations
- Sheet rise (Paywall, Style Picker if presented modal): native iOS sheet, large detent.
- Tab bar: scale 0.9 → 1 + opacity flick on tap (100ms ease-out).
- Featured card "Make wallpaper" tap: tap-down compresses to 0.97 scale (50ms).
- Style thumbnail selection: ring fades in (180ms ease-out).
- Crayon underline on SignIn tagline: optional draw-on animation (350ms ease-out) on first appearance.
- Artwork generation: skeleton state → fade in result.

### States
- Buttons: pressed (scale 0.97, 50ms), disabled (40% opacity, no shadow).
- PRO-locked: corner pill + tap routes to paywall.
- Empty (no kids yet, no artwork): out of scope but design language is consistent with the cream gradient SignIn aesthetic.

## State Management

Minimum data model:
```ts
type Kid = { id: string; name: string; age: number; emoji: string; colorTint: string; createdAt: Date };
type Artwork = { id: string; kidId: string; title: string; mediaUrl: string; medium: string; sizeIn?: string; createdAt: Date };
type Wallpaper = { id: string; artworkId: string; style: WallpaperStyle; renderUrl: string; createdAt: Date };
type Subscription = { tier: 'free' | 'pro'; renewsAt?: Date; trialUntil?: Date };
type WallpaperStyle = 'watercolor' | 'storybook' | 'cutpaper' | 'popart' | 'pencil' | 'embroidery' /* + more */;
```

Local UI state:
- Home: selected child filter (default: All), free generation count.
- Gallery: month sections (server-grouped), filter (kid).
- StylePicker: selected style, source artwork id.
- Paywall: selected plan (default: Yearly).

## Assets

The HTML prototypes use **synthetic SVG art** for both kid drawings and wallpaper previews. For production:

- **Kid artwork:** Replace with user-uploaded images. Display in same card containers (white card, 4–10pt inner padding, soft shadow). Preserve the "drawing on paper" framing.
- **Wallpaper previews:** Replace with real generated images from the model backend. The styles (`watercolor`, `storybook`, `cutpaper`, `popart`, `pencil`, `embroidery`) and their visual identity in `hifi-kit.jsx` (`HFWallpaper`) are illustrative — final renders should match the named style intent but will look different.
- **Brand mark:** The heart-in-rounded-square is a placeholder. Replace with the real Fridgeworthy brand mark.
- **Caveat font:** Google Fonts. License is OFL.
- **Apple logo glyph:** Use SF Symbol `apple.logo` natively, do not redraw.
- **Other glyphs:** All custom glyphs in `HFGlyph` (heart, plus, wand, palette, sparkle, photo, camera, share, crown, check, lock, chevrons, close) should be replaced with **SF Symbols** in native iOS where possible.

## Files

| File | Purpose |
|---|---|
| `Fridgeworthy Wireframes v3.html` | Entry point — loads React + the JSX bundle |
| `app-hifi.jsx` | Top-level composition; lays out the 6 screens on the design canvas |
| `hifi-kit.jsx` | Design primitives: `HFPhone`, `HFStatusBar`, `HFKidArt`, `HFWallpaper`, `HFGlyph`, `HFHand`, `HFBtn`. Source of truth for tokens (`HF` const). |
| `hifi-screens.jsx` | The six screens: `HFSignIn`, `HFHome`, `HFChildDetail`, `HFGallery`, `HFStylePicker`, `HFPaywall`, `HFTabBar` |
| `design-canvas.jsx` | Canvas presentation only — not part of the app. Ignore. |

Open the HTML in a browser to walk through the designs. Pan/zoom the canvas; click any artboard's "↗" to focus a single screen full-screen.

## Implementation notes for native SwiftUI

- Use `Color(hex:)` extension or define a `Color+Tokens` enum from the table above.
- Use `.system(.title, design: .default, weight: .bold)` (SF Pro) and avoid custom fonts except Caveat.
- Liquid-glass tab bar → `Material.thin` or `.bar` with `.background(.ultraThinMaterial)`.
- Sheet for Paywall → `.sheet(isPresented:)` with `.presentationDetents([.large])` and `.presentationCornerRadius(32)`.
- Artwork grid → `LazyVGrid` 3 cols, 6pt spacing.
- Featured card → custom `VStack` with `Image(.imageScale(.fit))`, then action row.
- Crayon underline → overlay an `Image(systemName:)` or a custom `Path` SVG-equivalent.
