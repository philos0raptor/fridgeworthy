# Hand up art

Fridgeworthy lets a parent collect a child's artwork and turn a week or month of it into a phone wallpaper. The collection should honor the original work as well as offer an artistic interpretation. A future store may use the saved and generated designs for prints, clothing, stickers, and other objects; commerce is outside this page.

## Page experience

- A parent enters Hand up art from the main app and chooses a child and either a week or a month.
- The page displays every saved artwork in that period, with its date, and offers the existing add-artwork flow when the collection is empty or incomplete.
- The parent chooses **Original collage** or **Styled wallpaper**. Both paths make a phone-shaped preview before the parent saves an image to Photos for use as a device wallpaper.
- Original collage lays out the source artwork without AI alteration. The output contains all selected pieces, with an orderly layout and useful phone wallpaper margins.
- Styled wallpaper uses the selected period's artwork and an existing style template to generate a refined artistic rendition. It must pass the selected child and date range to the generation service rather than silently using the child's latest art.
- Empty periods, missing artwork images, offline generation errors, and photo-library denial should have clear recovery paths. The app cannot directly set iOS wallpaper; copy must say to save the image and set it in iOS.

## Implementation calls

- Keep the existing SwiftUI, SwiftData, Supabase, and design-system conventions.
- Keep children separated; do not combine their artwork in one wallpaper.
- A week follows the device calendar's week boundaries; a month follows its calendar month.
- The current text-driven AI service can render a composition inspired by artwork descriptions and colors. A future image-conditioned model is needed for closer visual fidelity; this page must not present that text-driven output as a faithful copy.
- The store is future scope and should not add a dead button to the page.
