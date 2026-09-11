#!/usr/bin/env python3
"""Contract tests for the Supabase backend.

Every bug in the #9–#14 chain was an integration defect the compiler could not see:
a URL that 400s, a UUID that can never match, a response shape the endpoint never
returns, a retired model id, a JPEG labelled as PNG. They were each found by hand,
with curl, once. This file exists so that finding them again is a command rather
than an afternoon.

Usage:
    python3 tests/backend_contract_test.py                    # free checks only
    python3 tests/backend_contract_test.py --include-paid     # also spends API credit

Credentials are read from the environment, falling back to the local files the
project already uses. Nothing is prompted for and no secret is printed.

    SUPABASE_URL           default: parsed from Config/Secrets.swift
    SUPABASE_ANON_KEY      default: parsed from Config/Secrets.swift
    TEST_ACCOUNT_EMAIL     default: dev-test@fridgeworthy.test
    TEST_ACCOUNT_PASSWORD  required (env only — never stored in the repo)

Exit code is 0 only if every check that ran passed.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
import uuid
from dataclasses import dataclass, field
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SECRETS_SWIFT = REPO_ROOT / "fridgeworthy" / "fridgeworthy" / "Config" / "Secrets.swift"

# A 1x1 PNG. Enough to exercise upload and storage policy; the vision checks that need
# a real picture generate one instead.
TINY_PNG = bytes.fromhex(
    "89504e470d0a1a0a0000000d4946484452000000010000000108060000001f15c4"
    "890000000a49444154789c6360000002000100fdff03fa0000000049454e44ae426082"
)


# --------------------------------------------------------------------------- harness


@dataclass
class Results:
    passed: int = 0
    failed: int = 0
    skipped: int = 0
    failures: list[str] = field(default_factory=list)

    def ok(self, name: str, detail: str = "") -> None:
        self.passed += 1
        print(f"  \033[32mPASS\033[0m  {name}{f'  — {detail}' if detail else ''}")

    def fail(self, name: str, detail: str) -> None:
        self.failed += 1
        self.failures.append(f"{name}: {detail}")
        print(f"  \033[31mFAIL\033[0m  {name}\n        {detail}")

    def skip(self, name: str, why: str) -> None:
        self.skipped += 1
        print(f"  \033[33mSKIP\033[0m  {name}  — {why}")

    def check(self, name: str, condition: bool, detail: str = "") -> bool:
        if condition:
            self.ok(name, detail)
        else:
            self.fail(name, detail or "condition was false")
        return condition


def section(title: str) -> None:
    print(f"\n\033[1m{title}\033[0m")


def request(
    method: str,
    url: str,
    headers: dict[str, str] | None = None,
    body: bytes | dict | None = None,
) -> tuple[int, bytes, dict[str, str]]:
    """Returns (status, body, headers). HTTP errors are returned, not raised."""
    data = body
    headers = dict(headers or {})
    if isinstance(body, dict):
        data = json.dumps(body).encode()
        headers.setdefault("Content-Type", "application/json")

    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            return resp.status, resp.read(), dict(resp.headers)
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read(), dict(exc.headers or {})
    except urllib.error.URLError as exc:
        return 0, str(exc).encode(), {}


def as_json(payload: bytes):
    try:
        return json.loads(payload)
    except Exception:
        return None


# --------------------------------------------------------------------------- config


def read_secrets_swift() -> dict[str, str]:
    """Best-effort parse of the gitignored Secrets.swift, so local runs need no setup."""
    if not SECRETS_SWIFT.exists():
        return {}
    text = SECRETS_SWIFT.read_text()
    found = {}
    for key, pattern in (
        ("url", r'supabaseURL\s*=\s*"([^"]+)"'),
        ("anon", r'supabaseAnonKey\s*=\s*"([^"]+)"'),
    ):
        match = re.search(pattern, text)
        if match:
            found[key] = match.group(1)
    return found


def resolve_config() -> tuple[str, str, str, str] | None:
    local = read_secrets_swift()
    url = os.environ.get("SUPABASE_URL") or local.get("url", "")
    anon = os.environ.get("SUPABASE_ANON_KEY") or local.get("anon", "")
    email = os.environ.get("TEST_ACCOUNT_EMAIL", "dev-test@fridgeworthy.test")
    password = os.environ.get("TEST_ACCOUNT_PASSWORD", "")

    missing = [
        name
        for name, value in (
            ("SUPABASE_URL", url),
            ("SUPABASE_ANON_KEY", anon),
            ("TEST_ACCOUNT_PASSWORD", password),
        )
        if not value
    ]
    if missing:
        print(f"Cannot run: missing {', '.join(missing)}.")
        print("See the module docstring for how these are resolved.")
        return None
    return url.rstrip("/"), anon, email, password


# --------------------------------------------------------------------------- checks


def sign_in(base: str, anon: str, email: str, password: str) -> tuple[str, str] | None:
    status, payload, _ = request(
        "POST",
        f"{base}/auth/v1/token?grant_type=password",
        {"apikey": anon},
        {"email": email, "password": password},
    )
    data = as_json(payload) or {}
    token = data.get("access_token")
    if status != 200 or not token:
        return None
    user_id = (data.get("user") or {}).get("id", "")
    return token, user_id


def check_auth(r: Results, base: str, anon: str, token: str, user_id: str) -> None:
    """#9 — a session must reach Postgres, and the signup trigger must create a profile."""
    section("Auth and profile (#9)")
    headers = {"apikey": anon, "Authorization": f"Bearer {token}"}

    status, payload, _ = request(
        "GET", f"{base}/rest/v1/profiles?select=id,subscription_tier", headers
    )
    rows = as_json(payload) or []
    r.check(
        "signup trigger created a profiles row",
        status == 200 and any(row.get("id") == user_id for row in rows),
        f"HTTP {status}, {len(rows)} row(s) visible",
    )
    r.check(
        "RLS scopes profiles to the caller",
        len(rows) <= 1,
        f"saw {len(rows)} rows; a user must never see another's profile",
    )


def check_style_templates(r: Results, base: str, anon: str, token: str) -> None:
    """#11 — slugs are the cross-boundary identity and must match the Swift defaults."""
    section("Style template slugs (#11)")
    headers = {"apikey": anon, "Authorization": f"Bearer {token}"}

    status, payload, _ = request(
        "GET", f"{base}/rest/v1/style_templates?select=id,slug,name", headers
    )
    rows = as_json(payload) or []

    if not r.check("style_templates readable when authenticated", status == 200, f"HTTP {status}"):
        return

    # Anonymous callers must see nothing: the policy is auth.role() = 'authenticated'.
    anon_status, anon_payload, _ = request(
        "GET", f"{base}/rest/v1/style_templates?select=slug", {"apikey": anon}
    )
    anon_rows = as_json(anon_payload) or []
    r.check(
        "style_templates hidden from anonymous callers",
        len(anon_rows) == 0,
        f"anon saw {len(anon_rows)} row(s)",
    )

    r.check("every template has a slug", all(row.get("slug") for row in rows), f"{len(rows)} rows")

    expected = {
        "watercolor-garden",
        "geometric-mosaic",
        "pencil-sketch",
        "storybook-adventure",
        "cut-paper-collage",
        "pop-art-burst",
    }
    actual = {row.get("slug") for row in rows}
    # This is the #11 regression guard: if the Swift defaults in
    # StyleTemplateSyncService drift from the migration's backfill, an offline-seeded
    # style stops resolving server-side and every generation 404s.
    r.check(
        "server slugs match the Swift defaults exactly",
        actual == expected,
        f"missing {sorted(expected - actual)}, unexpected {sorted(actual - expected)}",
    )


def check_storage_isolation(r: Results, base: str, anon: str, token: str, user_id: str) -> None:
    """#10 — the artworks bucket holds photographs of children; paths must be scoped."""
    section("Artwork storage isolation (#10)")
    headers = {"apikey": anon, "Authorization": f"Bearer {token}"}
    png = {**headers, "Content-Type": "image/png"}

    own_path = f"{user_id}/{uuid.uuid4()}/{uuid.uuid4()}.png"
    status, _, _ = request("POST", f"{base}/storage/v1/object/artworks/{own_path}", png, TINY_PNG)
    uploaded = r.check("upload inside own prefix succeeds", status in (200, 201), f"HTTP {status}")

    foreign = f"{uuid.uuid4()}/{uuid.uuid4()}/{uuid.uuid4()}.png"
    status, payload, _ = request("POST", f"{base}/storage/v1/object/artworks/{foreign}", png, TINY_PNG)
    r.check(
        "upload into another user's prefix is rejected",
        status not in (200, 201),
        f"HTTP {status} — writing outside your own prefix must fail: {payload[:120]!r}",
    )

    if uploaded:
        status, payload, _ = request(
            "POST",
            f"{base}/storage/v1/object/sign/artworks/{own_path}",
            headers,
            {"expiresIn": 3600},
        )
        signed = (as_json(payload) or {}).get("signedURL")
        # The bucket is private, so a signed URL is the only way to render artwork.
        # getPublicURL on a private bucket is what #10 was originally about.
        r.check("own object can be signed for display", status == 200 and bool(signed), f"HTTP {status}")

        request("DELETE", f"{base}/storage/v1/object/artworks/{own_path}", headers)


def check_wallpaper_status_shape(r: Results, base: str, anon: str, token: str) -> None:
    """#13 — error_message must be selectable, or failures surface as a 120s timeout."""
    section("Wallpaper status shape (#13)")
    headers = {"apikey": anon, "Authorization": f"Bearer {token}"}

    status, payload, _ = request(
        "GET",
        f"{base}/rest/v1/wallpapers?select=id,status,image_url,error_message&limit=1",
        headers,
    )
    # A 400 here means the column is missing from the select the client actually uses,
    # which is exactly how a failed job became indistinguishable from a slow one.
    r.check(
        "client's select including error_message is accepted",
        status == 200,
        f"HTTP {status}: {payload[:160]!r}",
    )


def check_generate_rejects_bad_slug(r: Results, base: str, anon: str, token: str) -> None:
    """#11 — an unknown slug must 404 rather than silently generating something."""
    section("generate-wallpaper slug resolution (#11)")
    headers = {"apikey": anon, "Authorization": f"Bearer {token}"}

    status, payload, _ = request(
        "GET", f"{base}/rest/v1/children?select=id&limit=1", headers
    )
    children = as_json(payload) or []
    if not children:
        r.skip("unknown slug is rejected", "no child row to test against")
        return

    status, payload, _ = request(
        "POST",
        f"{base}/functions/v1/generate-wallpaper",
        headers,
        {"child_id": children[0]["id"], "style_slug": "definitely-not-a-real-style"},
    )
    body = as_json(payload) or {}
    r.check(
        "unknown slug is rejected with 404",
        status == 404 and "not found" in json.dumps(body).lower(),
        f"HTTP {status}: {payload[:160]!r}",
    )


def check_describe_artwork(r: Results, base: str, anon: str, token: str, user_id: str) -> None:
    """#10 and #17 — a caption and a real colour palette, both persisted. Spends credit."""
    section("describe-artwork (#10, #17) — spends Anthropic credit")
    headers = {"apikey": anon, "Authorization": f"Bearer {token}"}

    status, payload, _ = request("GET", f"{base}/rest/v1/children?select=id&limit=1", headers)
    children = as_json(payload) or []
    if not children:
        r.skip("describe-artwork populates description and palette", "no child row")
        return
    child_id = children[0]["id"]

    drawing = build_test_drawing()
    path = f"{user_id}/{child_id}/{uuid.uuid4()}.png"
    status, _, _ = request(
        "POST",
        f"{base}/storage/v1/object/artworks/{path}",
        {**headers, "Content-Type": "image/png"},
        drawing,
    )
    if status not in (200, 201):
        r.fail("describe-artwork populates description and palette", f"upload failed HTTP {status}")
        return

    status, payload, _ = request(
        "POST",
        f"{base}/rest/v1/artworks",
        {**headers, "Prefer": "return=representation"},
        {"child_id": child_id, "image_url": path},
    )
    rows = as_json(payload) or []
    if not rows:
        r.fail("describe-artwork populates description and palette", f"insert failed HTTP {status}")
        return
    artwork_id = rows[0]["id"]

    status, payload, _ = request(
        "POST", f"{base}/functions/v1/describe-artwork", headers, {"artwork_id": artwork_id}
    )
    body = as_json(payload) or {}

    # image_url holds a storage *path*, and the bucket is private. If the function ever
    # goes back to fetching it as a URL this fails here rather than silently captioning
    # nothing — which is how every prompt ended up as "colorful children's drawing".
    r.check(
        "describe-artwork returns a description",
        status == 200 and bool(body.get("description")),
        f"HTTP {status}: {payload[:200]!r}",
    )
    r.check(
        "describe-artwork returns a non-empty colour palette",
        isinstance(body.get("colors"), list) and len(body.get("colors") or []) > 0,
        f"colors={body.get('colors')!r} — empty means every prompt falls back to 'warm pastels'",
    )

    status, payload, _ = request(
        "GET", f"{base}/rest/v1/artworks?id=eq.{artwork_id}&select=description,color_palette", headers
    )
    stored = (as_json(payload) or [{}])[0]
    r.check(
        "description and palette are persisted",
        bool(stored.get("description")) and bool(stored.get("color_palette")),
        f"stored={stored!r}",
    )

    request("DELETE", f"{base}/rest/v1/artworks?id=eq.{artwork_id}", headers)
    request("DELETE", f"{base}/storage/v1/object/artworks/{path}", headers)


def check_generation_round_trip(r: Results, base: str, anon: str, token: str) -> None:
    """#12 — submit returns a handle immediately and polling drives it to complete."""
    section("Generation round trip (#12) — spends fal credit")
    headers = {"apikey": anon, "Authorization": f"Bearer {token}"}

    status, payload, _ = request("GET", f"{base}/rest/v1/children?select=id&limit=1", headers)
    children = as_json(payload) or []
    if not children:
        r.skip("generation completes", "no child row")
        return

    started = time.monotonic()
    status, payload, _ = request(
        "POST",
        f"{base}/functions/v1/generate-wallpaper",
        headers,
        {"child_id": children[0]["id"], "style_slug": "watercolor-garden"},
    )
    body = as_json(payload) or {}
    submit_seconds = time.monotonic() - started

    if not r.check(
        "submit returns processing without blocking on the render",
        status == 200 and body.get("status") == "processing",
        f"HTTP {status}: {payload[:200]!r}",
    ):
        return

    # The old code generated, downloaded and uploaded inside this request. If submit
    # ever starts taking render-length time again, it will time out on the edge
    # function's wall clock long before the user sees anything.
    r.check(
        "submit is fast enough to stay off the wall clock",
        submit_seconds < 15,
        f"took {submit_seconds:.1f}s",
    )

    wallpaper_id = body.get("wallpaper_id")
    final = {}
    for _ in range(40):
        time.sleep(3)
        status, payload, _ = request(
            "POST", f"{base}/functions/v1/check-wallpaper", headers, {"wallpaper_id": wallpaper_id}
        )
        final = as_json(payload) or {}
        if final.get("status") in ("complete", "failed"):
            break

    if not r.check(
        "polling drives the job to complete",
        final.get("status") == "complete",
        f"ended as {final.get('status')!r}: {str(final.get('error_message'))[:200]}",
    ):
        return

    image_url = final.get("image_url") or ""
    status, image, resp_headers = request("GET", image_url)
    content_type = resp_headers.get("Content-Type", "")
    r.check("the stored image is fetchable", status == 200 and len(image) > 1000, f"HTTP {status}")
    # fal renders JPEG; storing those bytes as image/png mislabels every wallpaper.
    r.check(
        "stored content type matches the actual bytes",
        (image[:3] == b"\xff\xd8\xff" and "jpeg" in content_type)
        or (image[:8] == b"\x89PNG\r\n\x1a\n" and "png" in content_type),
        f"content-type {content_type!r} vs magic {image[:4]!r}",
    )

    request("DELETE", f"{base}/rest/v1/wallpapers?id=eq.{wallpaper_id}", headers)


def build_test_drawing() -> bytes:
    """A deliberately childlike scene: house, sun, grass. Gives vision something real."""
    import struct
    import zlib

    size = 192
    rows = [[(135, 206, 250)] * size for _ in range(size)]
    for y in range(135, size):
        for x in range(size):
            rows[y][x] = (106, 190, 80)
    for y in range(size):
        for x in range(size):
            if (x - 150) ** 2 + (y - 40) ** 2 < 25**2:
                rows[y][x] = (255, 214, 0)
    for y in range(90, 142):
        for x in range(45, 112):
            rows[y][x] = (220, 80, 70)
    for y in range(68, 92):
        for x in range(38, 120):
            if abs(x - 79) < (y - 66) * 1.9:
                rows[y][x] = (120, 70, 50)

    raw = b"".join(
        b"\x00" + b"".join(struct.pack("BBB", *rows[y][x]) for x in range(size))
        for y in range(size)
    )

    def chunk(tag: bytes, data: bytes) -> bytes:
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


# --------------------------------------------------------------------------- main


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--include-paid",
        action="store_true",
        help="also run checks that call Anthropic and fal, which cost real money",
    )
    args = parser.parse_args()

    config = resolve_config()
    if config is None:
        return 2
    base, anon, email, password = config

    print(f"Target: {base}")
    print(f"Account: {email}")
    if not args.include_paid:
        print("Paid checks skipped — pass --include-paid to run them.")

    session = sign_in(base, anon, email, password)
    if session is None:
        print("\nCannot run: sign-in failed. Check TEST_ACCOUNT_PASSWORD.")
        return 2
    token, user_id = session

    r = Results()
    check_auth(r, base, anon, token, user_id)
    check_style_templates(r, base, anon, token)
    check_storage_isolation(r, base, anon, token, user_id)
    check_wallpaper_status_shape(r, base, anon, token)
    check_generate_rejects_bad_slug(r, base, anon, token)

    if args.include_paid:
        check_describe_artwork(r, base, anon, token, user_id)
        check_generation_round_trip(r, base, anon, token)
    else:
        section("Paid checks")
        r.skip("describe-artwork (#10, #17)", "needs --include-paid")
        r.skip("generation round trip (#12)", "needs --include-paid")

    print(f"\n\033[1m{r.passed} passed, {r.failed} failed, {r.skipped} skipped\033[0m")
    for failure in r.failures:
        print(f"  - {failure}")
    return 1 if r.failed else 0


if __name__ == "__main__":
    sys.exit(main())
