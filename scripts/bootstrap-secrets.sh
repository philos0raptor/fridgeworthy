#!/usr/bin/env bash
# Copy the gitignored config files into this checkout.
#
# AppConfig.swift references Secrets.swift, which is gitignored and untracked.
# A fresh clone or git worktree therefore FAILS TO COMPILE until these are copied in.
# The compile error is confusing ("cannot find 'Secrets' in scope") and invites the
# wrong fix: authoring a placeholder Secrets.swift and committing it. Don't.
#
# Usage:  ./scripts/bootstrap-secrets.sh [path-to-a-checkout-that-has-them]

set -euo pipefail

SOURCE="${1:-/Users/pheng/Projects/Playground/fridgeworthy}"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "$SOURCE" = "$DEST" ]; then
    echo "Source and destination are the same checkout ($DEST). Nothing to do."
    exit 0
fi

FILES=(
    "fridgeworthy/Config/Debug.xcconfig"
    "fridgeworthy/Config/Release.xcconfig"
    "fridgeworthy/fridgeworthy/Config/Secrets.swift"
)

missing=0
for f in "${FILES[@]}"; do
    if [ ! -f "$SOURCE/$f" ]; then
        echo "MISSING in source: $SOURCE/$f" >&2
        missing=1
    fi
done

if [ "$missing" -ne 0 ]; then
    cat >&2 <<'MSG'

Could not find the real config files in the source checkout.

Do NOT author these files yourself and do NOT commit placeholder values —
that leaks a fake config into git and hides the real problem.

Copy them from wherever your working configuration lives, or start from
the .template files and fill in real values locally (they stay gitignored).
MSG
    exit 1
fi

for f in "${FILES[@]}"; do
    cp "$SOURCE/$f" "$DEST/$f"
    echo "copied  $f"
done

echo
echo "Done. These files are gitignored — verify with: git status --short"
