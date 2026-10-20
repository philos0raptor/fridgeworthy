#!/usr/bin/env python3
"""Fast source-and-asset contract checks for the Fridgeworthy UI refresh."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "fridgeworthy" / "fridgeworthy"
ASSETS = APP / "Assets.xcassets"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def source(path: str) -> str:
    target = APP / path
    require(target.exists(), f"missing source: {target.relative_to(ROOT)}")
    return target.read_text()


def check_assets() -> None:
    names = [
        "FWFridge",
        "FWPhil",
        "FWStar",
        "FWNavHome",
        "FWNavGallery",
        "FWNavCapture",
        "FWNavAccount",
        "FWDigitZero",
        "FWDigitOne",
        "FWDigitTwo",
        "FWDigitThree",
        "FWDigitFour",
        "FWDigitFive",
        "FWDigitSix",
        "FWDigitSeven",
        "FWDigitEight",
        "FWDigitNine",
        "FWDigitColon",
        "FWDigitPercent",
    ]
    for name in names:
        image_set = ASSETS / f"{name}.imageset"
        manifest = image_set / "Contents.json"
        require(manifest.exists(), f"missing asset manifest: {name}")
        data = json.loads(manifest.read_text())
        filenames = [item.get("filename") for item in data.get("images", []) if item.get("filename")]
        require(filenames, f"asset has no image file: {name}")
        require((image_set / filenames[0]).exists(), f"asset image is missing: {name}/{filenames[0]}")


def check_foundations() -> None:
    tokens = source("Views/DesignSystem/FW.swift")
    for value in ("0xFFFCF8", "0x302B35", "0x004225", "0xEAE4F4", "0xE7EFF8", "0x756A91", "0xD996AA", "0x91B8DB", "0x97C4A1"):
        require(value in tokens, f"missing approved color token {value}")
    require("childColor" in tokens, "missing deterministic child color helper")

    background = source("Views/DesignSystem/FWPaperBackground.swift")
    require("LinearGradient" in background, "paper background must use a gradient")

    status = source("Views/DesignSystem/FWHandwrittenStatusBar.swift")
    require("TimelineView" in status, "custom status time must update periodically")
    require("batteryLevel" in status, "custom status must read live battery level")
    require("SystemStatusSnapshot" in status, "custom status must derive time and battery from one system snapshot")
    require("fallbackBatteryPercentage" not in status, "custom status must not invent a battery percentage")
    require("Capsule()" not in status, "custom status must not draw a fake Dynamic Island")
    require("snapshot.dateLabel" not in status, "custom status must not show the current system date")
    require("case \":\": 6.5" in status, "colon artwork must use its measured crop scale")
    require("case \"8\": 2.25" in status, "wide number artwork must use its measured non-clipping scale")
    require("case \"%\": 5.5" in status, "percentage artwork must use its measured crop scale")
    require("verticalOffset" in status, "off-center punctuation artwork must be aligned by its measured bounds")
    require("HStack(spacing: -2)" in status, "handwritten glyphs must leave the colon legible")
    require("accessibilityValue" in status, "custom status must expose its displayed values to VoiceOver")
    require("scaleEffect(0.7" in status, "handwritten time and battery should render at seventy percent scale")
    require("let inkColor" in status, "custom status must accept the screen's ink color")
    require("renderingMode(.template)" in status, "handwritten status artwork must support tinting")


def check_authentication() -> None:
    sign_in = source("Views/SignInView.swift")
    auth_service = source("Services/AuthService.swift")
    for copy in (
        "Hi parents",
        "Welcome back.",
        "Your family’s little masterpieces are right where you left them.",
    ):
        require(copy in sign_in, f"missing approved authentication copy: {copy}")
    require(sign_in.count("SignInWithAppleButton") == 1, "authentication should expose one Apple action")
    require("continueWithoutAuthentication" in auth_service, "debug builds need an explicit prototype-session entry point")
    require("authService.continueWithoutAuthentication()" in sign_in, "debug Apple CTA must enter the prototype session")
    require("#if DEBUG" in sign_in, "prototype authentication bypass must be limited to debug builds")
    require("Prototype only" in sign_in, "debug bypass must be clearly identified in accessibility metadata")
    require("AuthEntryMode" in sign_in, "authentication needs new/returning parent mode state")
    require("Already have an account?" in sign_in, "missing returning-parent route")
    require('Text("Use email")' not in sign_in, "production authentication must not show Use email")
    require("FWHandwrittenStatusBar" in sign_in, "authentication must use the custom status treatment")
    require("FWFridge" in sign_in, "authentication must use the supplied fridge drawing")
    require("FWPhil" in sign_in, "authentication must use the supplied Phil signature")
    require("Circle()" not in sign_in, "fridge drawing must not have a decorative color backing")
    require(sign_in.count("FW.Color.onboardingInk") >= 7, "onboarding text and artwork must use the deep-green ink")
    require(sign_in.count("renderingMode(.template)") >= 2, "fridge and signature drawings must support deep-green tinting")
    require(".signInWithAppleButtonStyle(.black)" in sign_in, "Apple's system button must retain an approved appearance")


def check_month_overview() -> None:
    home = source("Views/HomeView.swift")
    require("MonthCalendar.days" in home, "home must render the tested month grid")
    require("MonthCalendar.offset" in home, "home must navigate adjacent months")
    require("visibleMonth" in home and "selectedChild" in home, "home must retain month and child filter state")
    require("DragGesture" in home and "translation.width" in home, "home must support horizontal month swipes")
    require("showMonthPicker" in home and "FWMonthPicker" in home, "month heading must open the picker")
    require("Dictionary(grouping:" in home and "createdAt" in home, "artwork stars must group by creation day")
    require("FWMemoryMarker" in home, "completed days must render hand-drawn memory markers")
    require("ScrollView(.vertical" in home, "six-week months must remain reachable on compact screens")
    require("greetingSection" not in home, "parent greeting should be removed from the overview")
    require("featuredSection" not in home, "featured dashboard should be removed from the overview")
    require("selectedChild = selectedChild" not in home, "month navigation must not reset the child filter")

    marker = source("Views/Components/FWMemoryMarker.swift")
    require("colors.prefix" not in marker, "every artwork must retain its own marker")

    picker = source("Views/Components/FWMonthPicker.swift")
    require("ScrollView" in picker, "all month choices must be reachable on compact sheets")
    require(".large" in picker, "month picker must offer a larger presentation detent")


def check_navigation() -> None:
    tab_bar = source("Views/Navigation/FWTabBar.swift")
    main_tabs = source("Views/Navigation/MainTabView.swift")
    require("case shop" not in tab_bar, "shop must leave the primary navigation")
    for asset in ("FWNavHome", "FWNavCapture", "FWNavAccount"):
        require(asset in tab_bar, f"tab bar must use doodle asset {asset}")
    require("ultraThinMaterial" in tab_bar, "tab bar must retain a liquid-glass surface")
    require("children.isEmpty" in main_tabs, "capture must explicitly handle an empty child list")
    require("addChildRequestToken" in main_tabs, "empty capture must route to add-child guidance")
    require("captureRequiresChild" in main_tabs, "empty capture must explain why capture cannot start")
    require("Text(title)" not in main_tabs, "add-artwork actions must stay visually icon-only")
    require(".accessibilityLabel(title)" in main_tabs, "icon-only add-artwork actions must keep spoken labels")


def check_daily_memory_persistence() -> None:
    capture = source("ViewModels/CaptureViewModel.swift")
    service = source("Services/SupabaseService.swift")
    gallery = source("ViewModels/GalleryViewModel.swift")

    require("saveMemoryImage" in capture, "daily memories need a local-first image save path")
    require("updateMemoryNote" in capture, "daily memories need one shared editable note")
    require("createdAt: date" in capture, "memory photos must use the displayed day")
    require("title: trimmedNote.isEmpty ? nil : trimmedNote" in capture, "new memory photos must receive the normalized shared note")
    require("updateArtworkTitle" in service, "shared-note edits must sync through the service boundary")
    require('"title": title' in service, "artwork inserts must persist the shared note")
    require('"created_at":' in service, "artwork inserts must persist the selected day")
    require("let title: String?" in service, "remote artwork DTOs must decode the shared note")
    require("let createdAt: String" in service, "remote artwork DTOs must decode their creation day")
    require("case createdAt = \"created_at\"" in service, "remote artwork DTOs must map created_at")
    require("local.title = dto.title" in gallery, "remote sync must restore note edits")
    require("createdAt: dto.parsedCreatedAt" in gallery, "new remote records must retain their calendar day")


def check_daily_memory_view() -> None:
    daily = source("Views/DailyMemoryView.swift")

    require("struct DailyMemoryView" in daily, "daily memory screen is missing")
    require("FW.Font.caption(12" in daily, "day header must stay visually quiet")
    require('Button("Save")' not in daily, "daily memories must not expose a Save button")
    require("thumbnail" not in daily.lower(), "daily memories must not render a thumbnail strip")
    require("DailyMemoryNavigation.wrappedIndex" in daily, "photo cards must use tested looping behavior")
    require(daily.count(".frame(width: 292, height: 314)") >= 3, "the deck and every photo-card state must stay at the approved compact size")
    require('Image("FWNavCapture")' in daily, "the add-photo card must use the supplied doodle")
    require("FW.Color.lavender.opacity" not in daily, "the add-photo card must stay blank instead of showing the prior photo through it")
    require("What do you want to remember?" in daily, "message prompt must live inside the editor")
    require("isEditingNote" in daily, "saved messages must become editable when tapped")
    require("ToolbarItemGroup(placement: .keyboard)" in daily, "multiline editing needs a keyboard Done action")
    require("UIImage(contentsOfFile:" in daily, "saved photos must load from their local path")
    require("AsyncImage" in daily, "saved photos need a remote fallback")
    require("DailyMemoryNavigation.clampedTowardToday" in daily, "day swipes must stop at today")
    require("saveMemoryImage" in daily, "new draft photos must autosave")
    require("persistPendingImagesIfNeeded()" in daily.split(".onAppear", 1)[1].split(".onChange", 1)[0], "a photo selected before navigation must save when the day screen appears")
    require("onRequestPhoto(displayedDate)" in daily, "adding from an older empty day must keep that displayed date")
    require("updateMemoryNote" in daily, "shared message edits must persist")
    require("onDisappear" in daily, "leaving the entry must commit note changes")


def check_daily_memory_routing() -> None:
    home = source("Views/HomeView.swift")
    main_tabs = source("Views/Navigation/MainTabView.swift")

    require("onSelectDate" in home, "calendar days must expose a day-selection route")
    require("onSelectDate?(day.date, selectedChild)" in home, "calendar taps must preserve the selected day and child")
    require("DailyMemoryView(" in main_tabs, "the center tab must host the daily memory screen")
    require("pendingImages: $pendingImages" in main_tabs, "captured photos must flow into the daily memory screen")
    require("pendingImages.append(image)" in main_tabs, "camera and library results must join the active daily entry")
    require("memoryDate = date" in main_tabs, "calendar routing must preserve the selected date")
    require("memoryChild = child" in main_tabs, "calendar routing must preserve the selected child filter")
    require(".id(memoryRouteID)" in main_tabs, "changing day or child must reset the daily screen to the selected route")
    require("CaptureView(" not in main_tabs, "the legacy capture form must not interrupt the new daily flow")


def main() -> None:
    check_assets()
    check_foundations()
    check_authentication()
    check_month_overview()
    check_navigation()
    check_daily_memory_persistence()
    check_daily_memory_view()
    check_daily_memory_routing()
    print("ui design contract tests passed")


if __name__ == "__main__":
    main()
