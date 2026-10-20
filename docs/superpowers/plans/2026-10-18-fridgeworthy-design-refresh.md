# Fridgeworthy Design Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current authentication, home dashboard, and five-item tab bar with the approved Apple-first welcome, swipeable monthly memory overview, and four-item liquid-glass navigation.

**Architecture:** Keep the existing SwiftUI/SwiftData/service boundaries. Add one Foundation-only month-grid utility for testable calendar behavior, small reusable design-system views for paper backgrounds/status glyphs, and focused SwiftUI views for authentication and the monthly overview; `RootView` and `AuthService` continue to own session routing.

**Tech Stack:** Swift 5, SwiftUI, SwiftData, Observation, AuthenticationServices, UIKit battery APIs, asset catalogs, Python 3 contract tests, `swiftc`, Xcode 26.

**Spec:** `docs/superpowers/specs/2026-10-18-fridgeworthy-design-refresh.md`

## Global Constraints

- Deployment target remains iOS 26.0.
- No new network dependencies or backend/schema changes.
- Production authentication remains Sign in with Apple through `AuthService.signInWithApple(credential:)`.
- DEBUG email sign-in may remain as a non-primary developer fallback.
- The opened starred-day detail is deferred.
- Month navigation uses horizontal swipe plus a tappable month/year picker, without permanent arrows.
- Existing untracked drawing sources in `drawings/` are user-owned and must remain intact.
- Terms and Privacy do not invent external destinations before production URLs exist.

## Review Focus

- Non-Sunday calendar first weekdays must produce correct leading padding and seven-column rows; Task 1 tests Monday-first output.
- Leap-year February must render 29 numbered days; Task 1 tests February 2028.
- A simulator with unavailable battery state must still render a sensible percentage; Task 2 contract and build verify the fallback path exists.
- Multiple artworks on one day must produce multiple offset markers while child filtering removes unrelated markers; Task 4 contract checks the grouping and filter hooks.
- Capture with no child must return to the overview and surface add-child UI instead of silently doing nothing; Task 5 contract checks the empty-child branch.

---

### Task 1: Month calendar domain

**Files:**
- Create: `tests/month_calendar_test.swift`
- Create: `fridgeworthy/fridgeworthy/Models/MonthCalendar.swift`

**Interfaces:**
- Produces: `MonthCalendar.days(for:calendar:now:) -> [MonthDay?]`, `MonthCalendar.offset(_:by:calendar:) -> Date`, `MonthCalendar.isCurrentMonth(_:now:calendar:) -> Bool`, and `MonthCalendar.dayKey(for:calendar:) -> Date`.
- Consumed by: Task 4 month navigation, grid rendering, today state, and artwork grouping.

- [ ] **Step 1: Write the failing executable Swift test**

Add assertions for a Monday-first October 2026 grid, February 2028 day count, fixed-now today detection, month offset across a year boundary, and same-day key normalization.

- [ ] **Step 2: Run the test to verify it fails**

Run: `swiftc tests/month_calendar_test.swift fridgeworthy/fridgeworthy/Models/MonthCalendar.swift -o /tmp/fridgeworthy-month-calendar-test && /tmp/fridgeworthy-month-calendar-test`

Expected: FAIL because `MonthCalendar.swift` does not exist.

- [ ] **Step 3: Implement the Foundation-only calendar utility**

Create `MonthDay: Equatable` and the four static `MonthCalendar` functions. Always normalize the displayed month to its first day and pad the output to complete seven-day rows.

- [ ] **Step 4: Run the test to verify it passes**

Run the Step 2 command.

Expected: process exits 0 and prints `month calendar tests passed`.

- [ ] **Step 5: Commit**

Commit message: `feat: add month calendar domain`

### Task 2: Visual foundations and drawing assets

**Files:**
- Create: `tests/ui_design_contract_test.py`
- Create: `fridgeworthy/fridgeworthy/Assets.xcassets/FWFridge.imageset/*`
- Create: `fridgeworthy/fridgeworthy/Assets.xcassets/FWStar.imageset/*`
- Create: `fridgeworthy/fridgeworthy/Assets.xcassets/FWNavHome.imageset/*`
- Create: `fridgeworthy/fridgeworthy/Assets.xcassets/FWNavGallery.imageset/*`
- Create: `fridgeworthy/fridgeworthy/Assets.xcassets/FWNavCapture.imageset/*`
- Create: `fridgeworthy/fridgeworthy/Assets.xcassets/FWNavAccount.imageset/*`
- Create: `fridgeworthy/fridgeworthy/Assets.xcassets/FWDigit*.imageset/*`
- Create: `fridgeworthy/fridgeworthy/Views/DesignSystem/FWPaperBackground.swift`
- Create: `fridgeworthy/fridgeworthy/Views/DesignSystem/FWHandwrittenStatusBar.swift`
- Modify: `fridgeworthy/fridgeworthy/Views/DesignSystem/FW.swift`

**Interfaces:**
- Produces: approved `FW.Color` aliases, rounded/serif/handwritten typography helpers, `FW.childColor(at:)`, `FWPaperBackground`, `FWHandwrittenStatusBar`, and named catalog images.
- Consumed by: Tasks 3–5.

- [ ] **Step 1: Write the failing design contract test**

Assert the required image sets and JSON manifests exist, `FW.swift` declares the approved hex values, and the status component contains both a periodic time update and an unavailable-battery fallback.

- [ ] **Step 2: Run the test to verify it fails**

Run: `python3 tests/ui_design_contract_test.py`

Expected: FAIL listing missing assets/components.

- [ ] **Step 3: Add catalog assets and reusable foundations**

Copy—not move—the supplied drawings into named image sets. Implement the paper gradient and a custom status row that composes digit assets, updates time with `TimelineView`, reads `UIDevice.batteryLevel`, and falls back to `78` when unavailable.

- [ ] **Step 4: Run the contract test and app build**

Run: `python3 tests/ui_design_contract_test.py`

Expected: PASS.

Run: `xcodebuild -project fridgeworthy/fridgeworthy.xcodeproj -scheme fridgeworthy -destination 'generic/platform=iOS Simulator' build`

Expected: `** BUILD SUCCEEDED **` and no new source warnings.

- [ ] **Step 5: Commit**

Commit message: `feat: add keepsake design foundations`

### Task 3: Apple-first authentication presentation

**Files:**
- Modify: `tests/ui_design_contract_test.py`
- Rewrite: `fridgeworthy/fridgeworthy/Views/SignInView.swift`

**Interfaces:**
- Consumes: `FWPaperBackground`, `FWHandwrittenStatusBar`, `FWFridge`, and `AuthService.signInWithApple(credential:)`.
- Produces: `SignInView` with local `AuthEntryMode` state for new and returning parent copy.

- [ ] **Step 1: Extend the contract test and verify red**

Assert the three approved new-parent copy lines, the returning-parent copy, a single visible `SignInWithAppleButton`, the account-mode toggle, and the absence of a visible production `Use email` CTA.

Run: `python3 tests/ui_design_contract_test.py`

Expected: FAIL against the old sign-in source.

- [ ] **Step 2: Implement the approved authentication screen**

Replace the card deck with the fridge illustration, warm copy, Terms/Privacy affordances, Apple button, account-mode link, inline error, custom status row, paper gradient, and hidden system status bar. Preserve Apple credential scopes and error handling; keep DEBUG email access behind a non-primary developer-only gesture or menu.

- [ ] **Step 3: Verify contract and build**

Run the contract test and the generic iOS Simulator build.

Expected: both pass; build succeeds without new warnings.

- [ ] **Step 4: Commit**

Commit message: `feat: redesign Apple onboarding`

### Task 4: Swipeable monthly memory overview

**Files:**
- Modify: `tests/ui_design_contract_test.py`
- Create: `fridgeworthy/fridgeworthy/Views/Components/FWMonthPicker.swift`
- Create: `fridgeworthy/fridgeworthy/Views/Components/FWMemoryMarker.swift`
- Rewrite: `fridgeworthy/fridgeworthy/Views/HomeView.swift`
- Modify: `fridgeworthy/fridgeworthy/Views/Components/FWChildChip.swift`

**Interfaces:**
- Consumes: Task 1 `MonthCalendar` functions and Task 2 visual foundations/assets.
- Produces: current-month state, horizontal swipe month offset, month/year picker presentation, Today reset, selected-child filter, add-child UI, and artwork-derived markers.

- [ ] **Step 1: Extend the contract test and verify red**

Assert `HomeView` uses `MonthCalendar`, groups `Artwork.createdAt`, retains `selectedChild` while changing `visibleMonth`, handles a horizontal drag threshold, presents a month picker from the month heading, renders `FWMemoryMarker`, and contains no parent greeting/featured dashboard.

Run: `python3 tests/ui_design_contract_test.py`

Expected: FAIL against the dashboard home.

- [ ] **Step 2: Implement the month picker and memory marker**

`FWMonthPicker` selects month and year without arrows; `FWMemoryMarker` layers one supplied star per artwork with child palette colors and small deterministic offsets.

- [ ] **Step 3: Replace the home dashboard**

Render the month title, conditional Today pill, year control, child filters, weekday labels, and padded calendar cells. Swipe left reveals the next month; swipe right reveals the previous month. Tapping a completed date remains inert in this slice. Keep add-child alert/profile creation behavior.

- [ ] **Step 4: Verify logic, contract, and build**

Run the MonthCalendar executable test, the Python design contract, and the generic iOS Simulator build.

Expected: all pass and build succeeds.

- [ ] **Step 5: Commit**

Commit message: `feat: add monthly memory overview`

### Task 5: Four-item liquid-glass navigation

**Files:**
- Modify: `tests/ui_design_contract_test.py`
- Modify: `fridgeworthy/fridgeworthy/Views/Navigation/FWTabBar.swift`
- Modify: `fridgeworthy/fridgeworthy/Views/Navigation/MainTabView.swift`

**Interfaces:**
- Consumes: Task 2 nav assets and `FW.Color` tokens; existing `GalleryTabView`, `CaptureView`, and `MeView` destinations.
- Produces: `FWTab` cases `.home`, `.gallery`, `.capture`, `.me`; liquid pill selection; capture empty-child guard.

- [ ] **Step 1: Extend the contract test and verify red**

Assert four tab cases, no `.shop` in `FWTab`, named doodle assets in the bar, liquid-glass material, and an explicit `children.isEmpty` capture branch that routes to home and surfaces add-child guidance.

Run: `python3 tests/ui_design_contract_test.py`

Expected: FAIL against the five-item tab bar.

- [ ] **Step 2: Implement navigation and the empty-child guard**

Preserve gallery/capture/account functionality, remove shop from the primary switch, use the approved doodle images with accessibility labels, and show a lightweight alert when capture requires a child.

- [ ] **Step 3: Run final verification**

Run: `swiftc tests/month_calendar_test.swift fridgeworthy/fridgeworthy/Models/MonthCalendar.swift -o /tmp/fridgeworthy-month-calendar-test && /tmp/fridgeworthy-month-calendar-test`

Run: `python3 tests/ui_design_contract_test.py`

Run: `xcodebuild -project fridgeworthy/fridgeworthy.xcodeproj -scheme fridgeworthy -destination 'generic/platform=iOS Simulator' build`

Expected: both tests pass and build reports `** BUILD SUCCEEDED **` with only the documented pre-existing warnings.

- [ ] **Step 4: Commit**

Commit message: `feat: ship keepsake app refresh`
