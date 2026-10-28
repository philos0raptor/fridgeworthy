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
        "FWChildOutline1",
        "FWChildOutline2",
        "FWChildOutline3",
        "FWChildOutline4",
        "FWChildOutline5",
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
        "FWThemeSystem",
        "FWThemeDark",
        "FWThemeLight",
        "FWSettingsHeader",
    ]
    for name in names:
        image_set = ASSETS / f"{name}.imageset"
        manifest = image_set / "Contents.json"
        require(manifest.exists(), f"missing asset manifest: {name}")
        data = json.loads(manifest.read_text())
        filenames = [item.get("filename") for item in data.get("images", []) if item.get("filename")]
        require(filenames, f"asset has no image file: {name}")
        require((image_set / filenames[0]).exists(), f"asset image is missing: {name}/{filenames[0]}")

    theme_assets = {
        "FWThemeSystem": "pic-system.png",
        "FWThemeDark": "pic-dark.png",
        "FWThemeLight": "pic-light.png",
    }
    for asset_name, filename in theme_assets.items():
        image_set = ASSETS / f"{asset_name}.imageset"
        manifest = json.loads((image_set / "Contents.json").read_text())
        image_entry = next((image for image in manifest["images"] if image.get("filename")), None)
        require(image_entry is not None and image_entry.get("filename") == filename, f"{asset_name} should use {filename}")
        require((image_set / filename).read_bytes() == (ROOT / "drawings" / "system-theme" / filename).read_bytes(), f"{asset_name} should preserve the supplied PNG as-is")

    settings_header = ASSETS / "FWSettingsHeader.imageset"
    settings_header_manifest = json.loads((settings_header / "Contents.json").read_text())
    settings_header_image = next((image for image in settings_header_manifest["images"] if image.get("filename")), None)
    require(settings_header_image is not None and settings_header_image.get("filename") == "settings-icon.png", "settings header should use the supplied settings illustration")
    require((settings_header / "settings-icon.png").read_bytes() == (ROOT / "drawings" / "settings-icon.png").read_bytes(), "settings header illustration should be preserved as-is")


def check_foundations() -> None:
    tokens = source("Views/DesignSystem/FW.swift")
    for value in ("0xFFFCF8", "0x302B35", "0x004225", "0xEAE4F4", "0xE7EFF8", "0x756A91", "0xD996AA", "0x91B8DB", "0x97C4A1"):
        require(value in tokens, f"missing approved color token {value}")
    require("childColor" in tokens, "missing deterministic child color helper")
    require("static let childPalette = [maya, theo, iris, plum, golden, terracotta]" in tokens, "child palette must have six distinct family colors")

    background = source("Views/DesignSystem/FWPaperBackground.swift")
    require("LinearGradient" in background, "paper background must use a gradient")

    settings = source("Views/MeView.swift")
    require('Image("FWSettingsHeader")' in settings, "settings page should show the settings illustration")
    require(settings.index('Image("FWSettingsHeader")') < settings.index('settingsSection("Kids")'), "settings illustration should appear above the settings sections")
    require(".frame(width: 88, height: 100)" in settings and ".frame(maxWidth: .infinity)" in settings, "settings illustration should be centered at its intended size")
    require(".renderingMode(.template)" not in settings, "theme picker icons should preserve their supplied colors")
    require(".scaledToFit()" in settings, "theme picker icons should scale proportionally into their display frame")
    require(".frame(width: selected ? 30 : 24, height: selected ? 30 : 24)" in settings, "theme picker icons should use the enlarged fit sizes")

    status = source("Views/DesignSystem/FWHandwrittenStatusBar.swift")
    require("TimelineView" in status, "custom status time must update periodically")
    require("TimelineView(.everyMinute)" in status, "custom status time should refresh on minute boundaries")
    require("UIApplication.significantTimeChangeNotification" in status, "custom status time should refresh after significant system time changes")
    require("batteryLevel" in status, "custom status must read live battery level")
    require("SystemStatusSnapshot" in status, "custom status must derive time and battery from one system snapshot")
    require("fallbackBatteryPercentage" not in status, "custom status must not invent a battery percentage")
    require("Capsule()" not in status, "custom status must not draw a fake Dynamic Island")
    require("snapshot.dateLabel" not in status, "custom status must not show the current system date")
    require("case \":\": 6.5" in status, "colon artwork must use its measured crop scale")
    require("case \"8\": 2.25" in status, "wide number artwork must use its measured non-clipping scale")
    require("case \"%\": 5.5" in status, "percentage artwork must use its measured crop scale")
    require('case "%": 0' in status and 'case ":": -4' in status, "percent artwork should sit lower than the colon")
    require(".padding(.trailing, 10)" in status, "battery percentage should be inset from the screen edge")
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
    require("MonthCalendar.clampedOffset" in home, "home month navigation must stop at the current month")
    require("visibleMonth" in home and "selectedChild" in home, "home must retain month and child filter state")
    require("DragGesture" in home and "translation.width" in home, "home must support horizontal month swipes")
    require("showMonthPicker" in home and "FWMonthPicker" in home, "month heading must open the picker")
    require("Dictionary(grouping:" in home and "createdAt" in home, "artwork must group by creation day")
    require("FWEntryDots" in home, "completed days must render child-colored dots")
    require("childIDsWithEntries" in home and "Set((artworksByDay[key] ?? []).compactMap" in home, "calendar dots must represent each child once per entry day")
    require("children.map(\\.id)" in home and "orderedChildIDs:" in home, "calendar child colors must follow the family palette order")
    require("artworkCount: artworkCount" in home, "calendar accessibility must continue announcing photo count, not dot count")
    require("ScrollView(.vertical" in home, "six-week months must remain reachable on compact screens")
    require("greetingSection" not in home, "parent greeting should be removed from the overview")
    require("featuredSection" not in home, "featured dashboard should be removed from the overview")
    require("selectedChild = selectedChild" not in home, "month navigation must not reset the child filter")

    marker = source("Views/Components/FWEntryDots.swift")
    require('Image("FWStar")' not in marker, "calendar entry dots must replace star markers")
    require("Circle()" in marker and "ForEach" in marker, "each child entry must render as an individual dot")

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
    require("showSettingsSheet" in main_tabs and '.sheet(isPresented: $showSettingsSheet)' in main_tabs, "settings should open as a bottom sheet")
    require("onSettingsTap: {" in main_tabs and "showSettingsSheet = true" in main_tabs, "settings tab should present the settings sheet without replacing the underlying screen")
    require("onSettingsTap()" in tab_bar, "settings tab should route through its sheet presentation action")
    home_asset = json.loads((ASSETS / "FWNavHome.imageset" / "Contents.json").read_text())
    settings_asset = json.loads((ASSETS / "FWNavAccount.imageset" / "Contents.json").read_text())
    require(home_asset["images"][0].get("filename") == "calendar.svg", "home navigation should use the refined calendar vector")
    require(settings_asset["images"][0].get("filename") == "settings.svg", "settings navigation should use the settings drawing")
    require(".renderingMode(tab == .home ? .original : .template)" in tab_bar and "foregroundStyle(FW.Color.onboardingInk)" in tab_bar, "navigation drawings should preserve calendar accent colors and tint the other icons")
    calendar_svg = (ASSETS / "FWNavHome.imageset" / "calendar.svg").read_text()
    require('d="M0 0 C527.67 0 1055.34 0 1599 0 C1599 369.27 1599 738.54 1599 1119 C1071.33 1119 543.66 1119 0 1119 C0 749.73 0 380.46 0 0 Z " fill="#FEFEFE"' not in calendar_svg, "calendar vector must not include its opaque full-canvas background path")
    latest_calendar_svg = (ROOT / "drawings" / "calendar.svg").read_text()
    require(calendar_svg == latest_calendar_svg, "bundled calendar vector should match the latest user drawing")
    require('fill="#004225"' in calendar_svg and 'fill="#8b0000"' in calendar_svg, "calendar drawing should preserve its deep green and burgundy accents")
    require('.renderingMode(tab == .home ? .original : .template)' in tab_bar, "calendar must preserve its burgundy dot while other navigation icons stay tinted")
    require("scaleEffect(tab == .settings ? 0.8 : tab == .capture ? 1.9 : 1)" in tab_bar, "settings navigation drawing should render smaller while calendar and capture keep their sizing")


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
    require("guard let createdAt = dto.parsedCreatedAt" in gallery, "remote records must have a valid calendar day")
    require("createdAt: createdAt" in gallery, "new remote records must retain their calendar day")


def check_daily_memory_view() -> None:
    daily = source("Views/DailyMemoryView.swift")

    require("struct DailyMemoryView" in daily, "daily memory screen is missing")
    require("FW.Font.caption(12" in daily, "day header must stay visually quiet")
    require('Button("Save")' not in daily, "daily memories must not expose a Save button")
    require("thumbnail" not in daily.lower(), "daily memories must not render a thumbnail strip")
    require("DailyMemoryNavigation.wrappedIndex" in daily, "photo cards must use tested looping behavior")
    require("private var artworksForDisplayedDate: [Artwork]" in daily, "the daily entry must gather every child's artwork for the selected date")
    require("private var childrenWithArtworkOnDisplayedDate: [Child]" in daily, "the child selector must include only children with artwork that day")
    require("private var selectedChildArtworks: [Artwork]" in daily, "selecting a child must show only that child's photo stack")
    require("private var showsChildSelector: Bool" in daily and "childrenWithArtworkOnDisplayedDate.count > 0" in daily, "the child-name pill must appear whenever the displayed artwork has an associated child")
    require("private var childSelector: some View" in daily, "the daily entry must provide tappable child-name pills")
    require("selectedEntryChildID" in daily and "Text(child.name)" in daily, "child pills must expose and update the selected child's name")
    require("FW.Color.childColor(" in daily and "orderedChildIDs: orderedChildIDs" in daily, "child pills must use the established family palette")
    require('Text("\\(photoCount)")' not in daily, "child names must not show photo counts")
    require('Text("Maya · photo' not in daily and 'Text("Swipe photo' not in daily, "photo details must not appear below the artwork")
    require("private var photoDeck: some View" in daily and "cardOffset(for: index)" in daily, "the photo deck must keep stacked offset cards to hint at more artwork")
    require(daily.count(".frame(width: 292, height: 314)") >= 3, "the deck and every photo-card state must stay at the approved compact size")
    require('Image("FWNavCapture")' in daily, "the add-photo card must use the supplied doodle")
    require("FW.Color.lavender.opacity" not in daily, "the add-photo card must stay blank instead of showing the prior photo through it")
    require("What do you want to remember?" in daily, "message prompt must live inside the editor")
    require("isEditingNote" in daily, "saved messages must become editable when tapped")
    require('else if photoCount > 0' in daily, "photo entries without a note must still show the memory prompt")
    require('Text(note.isEmpty ? "What do you want to remember?" : note)' in daily, "old entries must use the consistent prompt until a message is entered")
    require("ToolbarItemGroup(placement: .keyboard)" in daily, "multiline editing needs a keyboard Done action")
    require("UIImage(contentsOfFile:" in daily, "saved photos must load from their local path")
    require("AsyncImage" in daily, "saved photos need a remote fallback")
    require("DailyMemoryNavigation.clampedTowardToday" in daily, "day swipes must stop at today")
    require("private var datesWithEntries: Set<Date>" in daily and "Set(allArtworks.compactMap" in daily, "the mini rail must derive marker days from saved artworks")
    require("artwork.child?.id == initialChild?.id" in daily, "mini rail markers must respect the active child filter")
    require("DailyMemoryNavigation.hasEntry(" in daily and "in: datesWithEntries" in daily, "the mini rail dot must indicate an entry rather than Today")
    require("else if dateIsToday" not in daily, "Today must not receive a marker solely for being Today")
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
    require("onDisplayedDateChanged: { photoTargetDate = $0 }" in main_tabs, "the add tab must track the date visible in the daily entry")
    require("isViewingMemory: selectedTab == .capture" in main_tabs, "the add tab must target the entry date when an entry is open")
    require('Text("Add artwork to \\(targetDateLabel)")' in main_tabs, "the photo source sheet must disclose the destination date")
    require("children: children" in main_tabs, "the photo source sheet must list the family's children")
    require("selectedChildID: photoTargetChild?.id" in main_tabs, "the photo source sheet must reflect the explicit child selection")
    require("onSelectChild: { photoTargetChild = $0 }" in main_tabs, "child choices must be retained as the artwork target")
    require(main_tabs.count("photoTargetChild = nil") >= 2, "each add-artwork flow must start without silently choosing a child")
    require(".disabled(selectedChildID == nil)" in main_tabs, "camera and library actions must wait for child selection")
    add_artwork_picker = main_tabs.split("private struct FWAddArtworkSheet: View {", 1)[1]
    require("FW.Color.childColor(" in add_artwork_picker, "child choices must use the established family color order")
    require("private var orderedChildIDs: [UUID]" in add_artwork_picker, "the add-artwork picker must define its own ordered child IDs")
    require("orderedChildIDs: orderedChildIDs" in add_artwork_picker, "child choices must use the picker's ordered family colors")
    require("private var childPickerHeight: CGFloat" in main_tabs, "child picker space must adapt to the number of names")
    require("let rowCount = (children.count + 1) / 2" in main_tabs, "child picker height must follow its two-column row count")
    require(".frame(height: childPickerHeight)" in main_tabs, "child picker must not reserve the full large-family scroll height for two children")
    require("private let outlineAssetNames" in main_tabs, "child outlines must use the supplied five variants")
    require("Int.random(in: outlineAssetNames.indices)" in main_tabs, "new child fields must receive a random hand-drawn outline")
    require(".renderingMode(.template)" in main_tabs, "hand-drawn child outlines must support tinting")
    require("foregroundStyle(FW.Color.onboardingInk)" in main_tabs, "hand-drawn child outlines must use the deep-green ink")
    require("onDisplayedDateChanged(newDate)" in source("Views/DailyMemoryView.swift"), "date rail and swipe changes must update the add target")
    daily_memory = source("Views/DailyMemoryView.swift")
    require(".scrollPosition(id: $railDatePosition, anchor: .center)" in daily_memory, "the date rail should track the centered date while the user drags")
    require(".viewAligned(limitBehavior: .alwaysByOne)" in daily_memory, "the date rail should naturally settle no more than one date per swipe")
    require(".onScrollPhaseChange" in daily_memory, "the selected date should commit when native scrolling settles")
    require("UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.7)" in daily_memory, "date changes should provide a stronger adjustable haptic")
    require("memoryDate = date" in main_tabs, "calendar routing must preserve the selected date")
    require("memoryChild = child" in main_tabs, "calendar routing must preserve the selected child filter")
    require(".id(memoryRouteID)" in main_tabs, "changing day or child must reset the daily screen to the selected route")
    require("CaptureView(" not in main_tabs, "the legacy capture form must not interrupt the new daily flow")


def check_settings() -> None:
    settings = source("Views/MeView.swift")
    require('settingsSection("Kids")' in settings, "settings must include the Kids section")
    require('settingsSection("Appearance")' in settings, "settings must include the Appearance section")
    require('settingsSection("App settings")' in settings, "settings must include the App settings section")
    require('settingsLabel("Fridge Theme"' in settings, "appearance must label the theme control Fridge Theme")
    require('settingsLabel("Memory Font"' in settings, "appearance must label the font control Memory Font")
    require('settingsLabel("Notifications"' in settings and 'settingsLabel("Reminder time"' in settings, "app settings must expose notifications and reminder time")
    require('actionRow("Review"' in settings and 'actionRow("Help"' in settings, "app settings must retain Review and Help")
    require('.navigationTitle("Settings")' not in settings, "settings page must not repeat its title in the navigation bar")
    require('FW.Font.body(20, weight: .regular)' in settings, "settings section headers must use regular weight")
    require('Menu {' in settings and 'themeIcon(selectedThemeAsset, selected: true)' in settings, "theme control should show only its current icon and reveal choices on tap")
    require('Text(selectedMemoryFontLabel)' in settings and '.font(memoryFontPreview(memoryFont))' in settings, "font control should display its selected font in that typeface")
    require('@AppStorage("fridgeTheme")' in settings and '.preferredColorScheme(selectedColorScheme)' in settings, "Fridge Theme must persist and apply the selected appearance")
    require('@AppStorage("memoryFont")' in settings, "Memory Font selection must persist")
    require('requestAuthorization(options: [.alert, .sound, .badge])' in settings and 'UNCalendarNotificationTrigger' in settings, "notification settings must schedule a daily reminder")
    require('Text("Parent")' not in settings and 'Text("Subscription")' not in settings, "parent and subscription sections must be removed")
    require('Text(child.avatarEmoji)' not in settings and 'ageText' not in settings, "kid rows must use color instead of emoji and omit age")
    require('child.artworks.count' in settings and 'FW.Color.childColor(' in settings, "kid rows must show artwork count and family color")
    require('Get Full Access' not in settings and 'Restore purchases' not in settings and 'Download' not in settings, "deferred settings rows must remain omitted")
    typography = source("Views/DesignSystem/FW.swift")
    require('UserDefaults.standard.string(forKey: "memoryFont")' in typography and 'case "handwritten"' in typography and 'case "serif"' in typography, "font choice must feed the shared typography tokens")
    editor = settings.split("struct EditChildSheet: View {", 1)[1]
    require('TextField("Child’s name", text: $child.name)' in editor, "editing a child name should autosave through the model binding")
    require("child.colorIndex = index" in editor, "choosing a child color should immediately persist the color")
    require('.strokeBorder(' in editor and 'isSelected ? FW.Color.onboardingInk' in editor, "selected child color should use a deep-green outlined dot")
    require('Image(systemName: "checkmark")' not in editor and "Capsule()" not in editor, "child color selector should stay minimal with dots only")
    require("@AppStorage(\"fridgeTheme\")" in editor and "@AppStorage(\"memoryFont\")" in editor, "child editor should use the selected theme and font")
    require('Button("Save")' not in editor and 'Button("Cancel"' not in editor, "autosaving child editor must not show save or cancel actions")
    for path in ("Views/HomeView.swift", "Views/DailyMemoryView.swift", "Views/Navigation/MainTabView.swift"):
        require("customIndex: child.colorIndex" in source(path), "custom child colors must remain consistent across app screens")
    child_model = source("Models/Child.swift")
    require("var colorIndex: Int?" in child_model, "child color selection must persist on the child model")


def main() -> None:
    check_assets()
    check_foundations()
    check_authentication()
    check_month_overview()
    check_navigation()
    check_daily_memory_persistence()
    check_daily_memory_view()
    check_daily_memory_routing()
    check_settings()
    print("ui design contract tests passed")


if __name__ == "__main__":
    main()
