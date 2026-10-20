# Daily Memory Entry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the approved calendar → day → memory flow with looping photo cards, automatic persistence, a shared editable message, and the existing bottom navigation kept visible.

**Architecture:** Keep `Artwork` as the persisted photo unit and treat same-day artwork records as one daily entry. Add a Foundation-only navigation helper for testable date and carousel behavior, a focused `DailyMemoryView` for the three UI states, and pass day/add-photo events through `MainTabView` so the existing tab bar stays mounted.

**Tech Stack:** Swift 5, SwiftUI, SwiftData, PhotosUI, UIKit, Supabase Swift, Python 3 source contracts, `swiftc`, Xcode 26.

**Spec:** `docs/superpowers/specs/2026-10-20-daily-memory-entry.md`

## Global Constraints

- Deployment target remains iOS 26.0.
- Preserve the three tabs Home, Add memory, and Settings.
- Add no dependency and make no Supabase schema change.
- Existing `Artwork.artworkDescription` and wallpaper generation behavior remain unchanged.
- Use `Artwork.title` as the shared daily message and the existing `title` and `created_at` Supabase columns.
- Return inserts new lines; a keyboard-toolbar Done action dismisses the keyboard and commits the message.
- Preserve all unrelated dirty-worktree changes.

## Review Focus

- Zero-photo days must not index into an empty carousel; Task 1 tests zero-count normalization and Task 3 renders the dedicated empty state.
- Carousel navigation must wrap in both directions for one, two, and three cards; Task 1 tests every boundary.
- Rightward day navigation must never move beyond the current day; Task 1 tests the clamp.
- A missing local image with a valid remote URL must remain displayable; Task 3 implements local/remote fallback rendering.
- Repeated autosave triggers must not duplicate a pending photo; Task 3 removes each draft only after one local insert and disables concurrent persistence.

---

### Task 1: Daily memory navigation domain

**Files:**
- Create: `fridgeworthy/fridgeworthy/Models/DailyMemoryNavigation.swift`
- Create: `tests/daily_memory_navigation_test.swift`

**Interfaces:**
- Produces: `DailyMemoryNavigation.wrappedIndex(_:delta:count:) -> Int`, `DailyMemoryNavigation.dayOffset(_:by:calendar:) -> Date`, `DailyMemoryNavigation.clampedTowardToday(_:by:now:calendar:) -> Date`, and `DailyMemoryNavigation.isToday(_:now:calendar:) -> Bool`.
- Consumed by: Task 3 photo and day gestures.

- [ ] **Step 1: Write the failing executable Swift test**

Assert zero/single-card safety, two- and three-card forward/backward wrap, previous-day movement, and next-day clamping at today.

- [ ] **Step 2: Run the test to verify it fails**

Run: `swiftc tests/daily_memory_navigation_test.swift fridgeworthy/fridgeworthy/Models/DailyMemoryNavigation.swift -o /tmp/fridgeworthy-daily-memory-test && /tmp/fridgeworthy-daily-memory-test`

Expected: FAIL because the production helper does not exist.

- [ ] **Step 3: Implement the Foundation-only helper**

Keep all calendar operations injected and compare days using `Calendar.isDate(_:inSameDayAs:)`.

- [ ] **Step 4: Run the executable test**

Expected: process exits 0 and prints `daily memory navigation tests passed`.

### Task 2: Daily entry persistence contract

**Files:**
- Modify: `fridgeworthy/fridgeworthy/Services/SupabaseService.swift`
- Modify: `fridgeworthy/fridgeworthy/ViewModels/CaptureViewModel.swift`
- Modify: `fridgeworthy/fridgeworthy/ViewModels/GalleryViewModel.swift`
- Modify: `tests/ui_design_contract_test.py`

**Interfaces:**
- Produces: `CaptureViewModel.saveMemoryImage(_:note:date:child:context:) async -> Bool`, `CaptureViewModel.updateMemoryNote(_:for:context:) async`, `SupabaseService.insertArtwork(id:childID:storagePath:title:createdAt:)`, and `SupabaseService.updateArtworkTitle(id:title:)`.
- Consumed by: Task 3 autosave and message editing.

- [ ] **Step 1: Extend the UI source contract and verify it fails**

Assert the memory-specific save/update methods, title and creation-date payload keys, and remote DTO synchronization of `title` and `created_at`.

- [ ] **Step 2: Implement local-first memory persistence**

Write the PNG and insert `Artwork(title:note, createdAt:date)` before network upload. Keep upload and AI description errors non-destructive to the local memory.

- [ ] **Step 3: Restore title/date during remote sync**

Decode `title` and `created_at`, update existing records, and populate new local records with both fields.

- [ ] **Step 4: Run the UI source contract**

Expected: PASS for the new persistence assertions.

### Task 3: Daily memory screen

**Files:**
- Create: `fridgeworthy/fridgeworthy/Views/DailyMemoryView.swift`
- Modify: `tests/ui_design_contract_test.py`

**Interfaces:**
- Consumes: Task 1 navigation helpers, Task 2 persistence methods, `FWPaperBackground`, `FWHandwrittenStatusBar`, `FWNavCapture`, and stored `Artwork` records.
- Produces: `DailyMemoryView(initialDate:initialChild:pendingImages:onRequestPhoto:)` with empty, today, and older-filled states.

- [ ] **Step 1: Extend the UI source contract and verify it fails**

Assert the quiet date header, no Save control or thumbnail strip, looping card helper calls, add-card asset, placeholder text, editable saved note, keyboard-toolbar Done action, local/remote image fallback, and horizontal day navigation.

- [ ] **Step 2: Implement the day state and shared message editor**

Filter queried artwork by displayed day and optional child. Keep the note field hidden until a saved note is tapped; use `@FocusState` and `ToolbarItemGroup(placement: .keyboard)` for Done.

- [ ] **Step 3: Implement the looping card stack**

Layer cards with deterministic offset/scale/z-index and use `wrappedIndex` for both swipe directions. Append the add-photo card for today.

- [ ] **Step 4: Implement autosave**

Persist newly appended pending images once, update the shared note on Done/disappear, and keep the active index valid as query results change.

- [ ] **Step 5: Run the domain and UI source tests**

Expected: both pass.

### Task 4: Calendar and tab-bar integration

**Files:**
- Modify: `fridgeworthy/fridgeworthy/Views/HomeView.swift`
- Modify: `fridgeworthy/fridgeworthy/Views/Navigation/MainTabView.swift`
- Modify: `tests/ui_design_contract_test.py`

**Interfaces:**
- Consumes: Task 3 `DailyMemoryView`.
- Produces: `HomeView.onSelectDate`, selected day/child state in `MainTabView`, and parent-managed camera/library delivery into the active daily memory.

- [ ] **Step 1: Extend the UI source contract and verify it fails**

Assert calendar cells call `onSelectDate`, the capture tab renders `DailyMemoryView`, selected camera/library images append to pending images, and the tab bar remains outside the page switch.

- [ ] **Step 2: Make calendar dates interactive**

Wrap every real day cell in a plain button that forwards the date and active child filter.

- [ ] **Step 3: Route day and photo events through `MainTabView`**

Selecting a calendar day activates `.capture` with that day; the center tab opens the source chooser and selected images activate today’s entry. Requests from the add-photo card reuse the same chooser.

- [ ] **Step 4: Run all local tests and build**

Run the existing calendar/layout/status tests, the new daily-memory test, `python3 tests/ui_design_contract_test.py`, and the generic iOS Simulator build.

Expected: all executable tests and contracts pass, and Xcode reports `** BUILD SUCCEEDED **` with no new source warnings.

### Task 5: Manual interaction verification

**Files:**
- No source changes expected unless verification finds a defect.

**Interfaces:**
- Consumes: completed Tasks 1–4.
- Produces: verified simulator behavior for the approved states.

- [ ] **Step 1: Launch the app in an iPhone simulator**

Verify the current date opens as Today, an older empty date shows the minimal prompt, and an older filled date shows the message and overlapping cards.

- [ ] **Step 2: Exercise gestures and editing**

Verify photo swipes wrap, day swipes stop at today, tapping a saved message enables editing, Return inserts a line, and keyboard Done dismisses and persists.

- [ ] **Step 3: Exercise add-photo routing**

Verify the center navigation and today add card both reach the camera/library chooser and return the selected image to Today without hiding the bottom navigation.
