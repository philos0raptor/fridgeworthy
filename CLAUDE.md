# Fridgeworthy

iOS app that turns a kid's artwork into a phone wallpaper.
Capture drawing → AI describes it → pick a style → generate wallpaper → save/share.

## Layout

Single repo, both halves of one contract:

```
fridgeworthy/          iOS app (SwiftUI + SwiftData + MVVM)
  fridgeworthy.xcodeproj
  Config/              xcconfig files (REAL ONES ARE GITIGNORED)
  fridgeworthy/
    Models/            SwiftData @Model types
    Services/          all network/persistence access
    ViewModels/        @Observable, @MainActor
    Views/             SwiftUI + DesignSystem/
supabase/
  migrations/          001_initial_schema.sql  (schema + RLS + storage + seed)
  functions/           Deno edge functions: describe-artwork, generate-wallpaper
docs/                  implementation plans
```

The app and backend are coupled by contract: `SupabaseService` calls the edge functions,
and the SwiftData models mirror the SQL columns. A change on one side usually needs the other.

## Build

```bash
xcodebuild -project fridgeworthy/fridgeworthy.xcodeproj \
  -scheme fridgeworthy \
  -destination 'generic/platform=iOS Simulator' build
```

Expect `** BUILD SUCCEEDED **`. Baseline is 0 errors, 7 warnings — do not treat those
7 as something you introduced.

## FIRST STEP IN ANY FRESH WORKTREE — bootstrap secrets

`fridgeworthy/fridgeworthy/Config/AppConfig.swift` references `Secrets.supabaseURL`,
`Secrets.supabaseAnonKey`, `Secrets.revenueCatAPIKey`. Those live in `Secrets.swift`,
which is **gitignored and untracked** — so a fresh worktree checks out without it and
**the build fails to compile**.

Copy them in before building:

```bash
MAIN=/Users/pheng/Projects/Playground/fridgeworthy
cp "$MAIN/fridgeworthy/Config/Debug.xcconfig"   fridgeworthy/Config/
cp "$MAIN/fridgeworthy/Config/Release.xcconfig" fridgeworthy/Config/
cp "$MAIN/fridgeworthy/fridgeworthy/Config/Secrets.swift" fridgeworthy/fridgeworthy/Config/
```

**Never author these files yourself, and never commit them.** If the copy fails, stop and
report it. Inventing placeholder secret values leaks a fake config into git and hides the
real problem.

## Conventions

- async/await throughout. No Combine unless reactivity genuinely requires it.
- All Supabase access goes through a `Services/` class. Never call Supabase from a ViewModel.
- API keys (fal.ai, Anthropic) are Supabase secrets, server-side only. Never in the app.
- Negative prompts always include: `blurry, low quality, text, watermark, logo, cropped,
  deformed, photorealistic children, realistic child faces`
- Commits end with: `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`

## Known state — read before claiming anything works

- **No tests. No CI.** A green build proves the code compiles and nothing more.
- The core generation loop does **not** currently work end to end. Open issues #9–#14 are
  the chain of defects preventing it. Every one is a runtime/integration bug the compiler
  cannot see.
- `debugSkipAuth` (`Views/RootView.swift`) is `true` in DEBUG and leaves
  `authService.currentUserID` nil, so uploads never reach Postgres. Testing the real data
  path requires turning it off and having a real session.
