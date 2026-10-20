# Fridgeworthy Design Refresh

## Intent

Bring the existing SwiftUI app in line with the approved Paper direction: a warm, bookish family keepsake rather than a generic content dashboard. The first usable slice is the Apple-first authentication experience, the monthly memory overview, and the liquid-glass navigation shared by the app.

## Goals

- Replace the current sign-in presentation with the approved parent-oriented welcome experience.
- Keep the real Supabase Sign in with Apple implementation and remove production email entry from the primary flow.
- Make the authenticated home screen a monthly calendar whose completed days are marked by child-colored, hand-drawn stars.
- Let parents filter the month by child and add a child from the same rail.
- Preserve capture/gallery/account destinations while giving navigation the approved four-item liquid-glass treatment.
- Centralize the approved colors, type, spacing, radii, surfaces, and child palette in the SwiftUI design system.
- Use the supplied drawings and handwritten number assets throughout the interface.

## Non-goals

- Do not design or implement the opened starred-day detail yet.
- Do not change the Supabase schema, edge functions, wallpaper generation flow, or RevenueCat behavior.
- Do not add email/password as a production authentication option.
- Do not add social-proof counts or download totals.

## Approved experience

### Authentication

- Hide the ordinary iOS status bar on the custom welcome surface and render the supplied handwritten time and battery glyphs dynamically.
- Use `drawings/fridge.png` as the central illustration.
- New-parent copy: “Welcome to Fridgeworthy.” followed by “A little home for the art, stories, and proud moments your kids bring home.” and “So the little things they make can stay close.”
- Present one native black Sign in with Apple action.
- Keep Terms and Privacy affordances above the action.
- Keep “Already have an account? Sign in” as a returning-parent route; it changes the surrounding copy but invokes the same Apple authorization flow.
- Successful authentication continues through the existing `AuthService` and `RootView` session routing.

### Month overview

- Remove the parent greeting and dashboard cards from the home surface.
- Show the current month, a compact year control, and an All/child filter rail.
- Move to adjacent months with a horizontal swipe that snaps one month at a time.
- Tapping the month heading opens a compact month/year picker for larger jumps.
- Do not show permanent previous/next arrows. When the visible month is not the current month, show a temporary `Today` pill that returns to the current month.
- Render a seven-column calendar using the supplied handwritten number drawings.
- A day with artwork receives a hand-drawn star layered over the date. Each child has a stable pastel color. Multiple children on the same date produce offset overlapping stars.
- The current date receives a thin lavender ring.
- Tapping an unimplemented day has no navigation effect in this slice; opened-day treatment remains deferred.
- When no child exists, keep an inline add-child invitation without replacing the calendar structure.

### Navigation

- Use four destinations: month overview, gallery, capture, and account.
- Remove the shop destination from the primary tab bar without deleting its existing implementation.
- Use supplied doodle assets for overview, gallery, capture, and account where available, with SF Symbols only as a resilient fallback.
- Present the selected item as a soft lavender circular surface inside a translucent pill.

## Visual foundations

- Background: paper white `#FFFCF8` fading from lavender `#EAE4F4` and sky `#E7EFF8` near the top.
- Ink: `#302B35`; muted ink: `#77717D`; borders: `#E7E0E7`; primary lavender: `#756A91`.
- Child palette: Maya pink `#D996AA`, Theo blue `#91B8DB`, Iris green `#97C4A1`, then repeat deterministically for additional children.
- Primary interface typography uses rounded system typography; dates and custom status details use the bundled/supplied handwriting assets.
- Surfaces stay airy with large radii, low-contrast borders, and restrained shadows.

## Functional constraints

- Deployment target remains iOS 26.
- Continue using SwiftUI, SwiftData, Observation, AuthenticationServices, and the existing service boundaries.
- No new network dependency.
- Artwork completion markers derive from `Artwork.createdAt` and the selected child filter.
- Calendar calculations must respect the injected `Calendar` time zone and first weekday.
- Month navigation keeps the selected child filter active.
- Terms and Privacy remain styled affordances until production destinations are supplied; this slice must not invent external legal URLs.
- Preserve DEBUG email sign-in access only as a developer fallback, not as a visible production CTA.

## Acceptance

- The app builds for a generic iOS Simulator.
- Calendar logic is covered by an executable Swift test for month padding, leap-year day count, today state, and date grouping.
- The welcome screen can invoke existing Sign in with Apple and shows errors without leaving the flow.
- The authenticated home renders the current month from real SwiftData children/artworks and filters markers by child.
- The four-item liquid-glass navigation continues to launch capture, gallery, and account functionality.
