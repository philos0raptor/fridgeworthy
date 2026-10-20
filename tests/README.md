# Tests

## What is here

`backend_contract_test.py` — contract tests against a real Supabase project.

Every bug in the #9–#14 chain was an integration defect the compiler could not see: a URL
that 400s, a UUID that can never match, a response shape the endpoint never returns, a
retired model id, a JPEG labelled as PNG. Each was found once, by hand, with curl. These
tests exist so finding them again is a command rather than an afternoon.

They are deliberately **contract** tests, not unit tests. The defects live in the seams
between the app, Postgres, storage policies, and two external APIs — which is exactly
where unit tests do not look.

## Running them

```bash
TEST_ACCOUNT_PASSWORD=... python3 tests/backend_contract_test.py
```

`SUPABASE_URL` and `SUPABASE_ANON_KEY` are read from the environment, falling back to
parsing the gitignored `Config/Secrets.swift`, so a local run usually needs only the
password. Nothing is prompted for and no secret is printed.

### Paid checks

```bash
TEST_ACCOUNT_PASSWORD=... python3 tests/backend_contract_test.py --include-paid
```

This adds the checks that call Anthropic (`describe-artwork`) and fal
(`generate-wallpaper` → `check-wallpaper`). They cost real money — roughly $0.05 a run —
which is why they are opt-in and why CI does not run them on every push.

## What each check defends

| Check | Guards against |
|---|---|
| signup trigger creates a profiles row | #9 — a session that never reaches Postgres |
| RLS scopes profiles to the caller | one user reading another's profile |
| style_templates hidden from anonymous callers | the sync silently falling back to local seeds |
| server slugs match the Swift defaults **exactly** | #11 — drift between the migration backfill and `StyleTemplateSyncService`, which makes every generation 404 |
| upload into another user's prefix is rejected | #10 — the bucket holds photographs of children |
| own object can be signed for display | #10 — `getPublicURL` on a private bucket |
| client's select including `error_message` is accepted | #13 — failures presenting as a 120s timeout |
| unknown slug is rejected with 404 | #11 — silently generating from the wrong style |
| describe-artwork returns a description | #10 — captions failing silently, so every prompt became "colorful children's drawing" |
| describe-artwork returns a colour palette | #17 — every prompt falling back to "warm pastels" |
| submit returns processing quickly | #12 — rendering on the edge function's wall clock |
| polling drives the job to complete | #12 — reading a response shape the queue never returns |
| stored content type matches the actual bytes | JPEG stored as `image/png` |

## Continuous integration

`.github/workflows/ci.yml` builds the app on every push and pull request, and runs the
free contract checks when repository secrets are configured.

The build job copies `Secrets.swift.template` over `Secrets.swift` first. A fresh
checkout has no `Secrets.swift` — it is gitignored — and the resulting error, `cannot
find 'Secrets' in scope`, does not mention secrets at all. The template's placeholders
are all a compile needs; no real credentials are involved.

To enable the contract job, set these repository secrets:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `TEST_ACCOUNT_EMAIL`
- `TEST_ACCOUNT_PASSWORD`

Without `SUPABASE_URL` the job skips rather than fails, so the workflow is useful before
the secrets exist.

## Not covered yet

**There is no Xcode test target**, so nothing here tests Swift code directly — no
ViewModel tests, and no XCUITest. That gap is why verifying the sign-in flow in #9
required a human to tap through the simulator: `simctl` has no tap command, and the
scripted alternatives need macOS Accessibility permission.

Adding the target is the remaining part of #18.
