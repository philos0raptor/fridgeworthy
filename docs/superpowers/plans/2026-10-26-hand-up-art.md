# Hand up art Implementation Plan

**Implementation note (2026-10-26):** The page, local collage, and period-scoped backend request are implemented on `codex/hand-up-art`. Local unit and UI contract checks and the iOS Simulator build pass. A signed-in visual walkthrough, live backend contract run, and deployment have not been performed; those depend on a test session and backend rollout. The styled renderer remains the existing text-driven model described in the spec.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an artwork collection page that makes weekly or monthly original collages and period-scoped styled wallpapers.

**Architecture:** A Foundation period selector defines date bounds and filters local art. A SwiftUI page renders the collection, hands original artwork to a local collage renderer, and sends styled generation through the existing service with the same period bounds. The Supabase function selects only that child's artwork in the date range.

**Tech Stack:** SwiftUI, SwiftData, UIKit image rendering, Photos, Supabase Edge Functions (Deno/TypeScript).

**Spec:** `docs/superpowers/specs/2026-10-26-hand-up-art-design.md`

## Global Constraints

- Preserve existing uncommitted project settings and drawings.
- Keep artwork child-scoped and date-scoped.
- Describe the existing AI output as an interpretation, not a faithful visual copy.
- Saving to Photos is the available iOS route toward setting a device wallpaper.

## Review Focus

- Empty periods must never send a generation request.
- Dates at the period boundary must belong to exactly one period.
- Missing local and remote image data must not crash collage creation.
- Server must verify the child before selecting artwork.
- A generation failure must remain visible with retry.

---

### Task 1: Period selection

**Files:** Create `fridgeworthy/fridgeworthy/Models/ArtworkPeriod.swift`; create `tests/artwork_period_test.swift`.

**Interfaces:** `ArtworkPeriod` stores week/month and anchor date, exposes start/end, display label, and `contains(_:)`.

- [ ] Write failing boundary tests for a week, month, empty range, and adjoining ranges.
- [ ] Run the test and verify failure.
- [ ] Implement period calculation using `Calendar.dateInterval(of:for:)` and half-open bounds.
- [ ] Run the test and verify pass.

### Task 2: Original collage

**Files:** Create `fridgeworthy/fridgeworthy/Services/ArtworkCollageRenderer.swift`.

**Interfaces:** `render(images: [UIImage], title: String) -> UIImage?` returns a portrait image sized for device wallpaper, preserving every input image.

- [ ] Add a focused renderer test or visual fixture that checks dimensions and the zero-image path.
- [ ] Verify it fails before implementation.
- [ ] Implement a deterministic layout with neutral background, original image proportions, and safe top margin.
- [ ] Verify output and visually inspect a fixture.

### Task 3: Styled period contract

**Files:** Modify `SupabaseService.swift`, `WallpaperGenerationViewModel.swift`, `WallpaperView.swift`, and `supabase/functions/generate-wallpaper/index.ts`; add a contract test.

**Interfaces:** Pass period start and end as ISO8601 strings from client to function; reject invalid ranges, query `created_at >= start` and `< end` for the verified child, and retain the chosen artwork IDs in the job.

- [ ] Write failing contract checks for bounded selection and invalid bounds.
- [ ] Verify failure.
- [ ] Extend client request, view model, and function to use one date range.
- [ ] Run contract and build checks.

### Task 4: Page and navigation

**Files:** Create `fridgeworthy/fridgeworthy/Views/HandUpArtView.swift`; modify `MainTabView.swift` and the relevant navigation entry.

**Interfaces:** Pick child/period, show selected art, preview original collage, enter existing style picker, and save resulting image to Photos.

- [ ] Add a UI design contract for reachable page and required actions.
- [ ] Verify failure.
- [ ] Implement page using existing design tokens and app navigation.
- [ ] Run contract, Swift checks, and iOS Simulator build.

### Task 5: Review and verification

- [ ] Inspect changes for source-image fidelity, copy, accessibility, and empty/error states.
- [ ] Run all non-paid local tests and a full simulator build.
- [ ] Report the visual-fidelity limitation of the current text-driven AI backend.
