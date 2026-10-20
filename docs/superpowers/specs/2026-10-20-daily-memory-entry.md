# Fridgeworthy Daily Memory Entry

## Intent

Turn each calendar day into a lightweight family memory: one shared message with one or more artwork photos. The experience should feel like paging through a small stack of keepsakes, not managing a gallery or form.

## Approved experience

- The calendar remains the primary entry point: calendar → day → memory.
- The center add-memory navigation action opens the existing camera/library chooser and then opens today’s memory.
- The bottom navigation remains visible throughout the memory experience.
- The top label is visually quiet: `Today` for the current day or `MM.dd` for older days, using the app’s rounded interface font at the same small size.
- Older days show a small `Today` action on the upper-right; there is no curved return arrow.
- Swiping the day surface left moves to the previous day. Swiping right moves toward today and never advances into the future.
- Empty days show only the supplied `add-button.png` artwork and “There’s still room for this day”.
- Filled days show overlapping photo cards. Adjacent cards peek from behind the active card.
- Swiping directly on the photo stack advances through the cards and wraps continuously from the last card to the first, and from the first to the last.
- Today’s photo stack ends with a blank add-photo card using `add-button.png`; choosing it opens the camera/library chooser.
- There is no thumbnail strip below the active photo.
- The shared message uses “What do you want to remember?” as an in-field placeholder. Empty saved messages render no separate text.
- Tapping a saved message enables editing.
- There is no visible Save button. Photos save automatically, and message edits save when the user taps a keyboard-toolbar Done action or leaves the screen.
- The keyboard Return key continues to create new lines; Done appears in the keyboard toolbar and dismisses the keyboard.

## Data behavior

- Existing `Artwork` records remain the persisted photo unit.
- A daily entry is the set of artworks sharing a calendar day, optionally narrowed to the child chosen on the month view.
- The entry’s shared message is stored in `Artwork.title` and synchronized across every artwork in that day entry.
- New photos use the currently displayed day as `createdAt`, including photos added to an older empty day.
- Uploads continue through `SupabaseService`; the existing `artworks.title` and `artworks.created_at` columns are used without a schema migration.
- Remote artwork synchronization restores title and creation date so the day grouping survives reinstall or another device.
- Existing wallpaper-generation behavior and `artworkDescription` remain unchanged.

## Constraints

- Deployment target remains iOS 26.
- Use SwiftUI, SwiftData, PhotosUI, UIKit camera capture, and the existing service boundaries.
- Add no new network dependency and make no Supabase schema change.
- Preserve the current three-item liquid-glass navigation: Home, Add memory, Settings.
- Preserve all current user-owned and uncommitted work.

## Acceptance

- Tapping any calendar date opens that date’s memory without hiding the bottom navigation.
- Choosing or taking a photo from the center navigation action opens today’s memory with the image visible.
- Empty, today, and older-filled states match the approved browser mockup.
- The photo carousel wraps in both directions.
- The add-photo card can append another image to today’s memory.
- Message editing exposes a keyboard Done action and persists one shared message across the day’s artwork records.
- The app builds for a generic iOS Simulator and the executable domain tests and UI source contracts pass.
