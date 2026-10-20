import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
enum SystemStatusSnapshotTests {
static func main() {
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(secondsFromGMT: -7 * 60 * 60)!

let date = Date(timeIntervalSince1970: 1_760_893_080) // 2025-10-19 09:58 PDT
let snapshot = SystemStatusSnapshot(
    date: date,
    batteryLevel: 0.63,
    locale: Locale(identifier: "en_US"),
    calendar: calendar
)

expect(snapshot.timeGlyphs == "9:58", "time glyphs should follow the system's 12-hour locale")
expect(snapshot.batteryPercentage == 63, "battery level should round to the displayed percentage")
expect(snapshot.batteryGlyphs == "63%", "battery glyphs should mirror the battery percentage")
expect(snapshot.accessibilityValue.contains(snapshot.timeLabel), "accessibility status should announce the displayed time")
expect(snapshot.accessibilityValue.contains("63% battery"), "accessibility status should announce the displayed battery")
expect(!snapshot.accessibilityValue.contains("Oct"), "accessibility status should omit the date")

let unavailableBattery = SystemStatusSnapshot(
    date: date,
    batteryLevel: -1,
    locale: Locale(identifier: "en_US"),
    calendar: calendar
)
expect(unavailableBattery.batteryPercentage == nil, "unavailable battery data must not use a fabricated fallback")
expect(unavailableBattery.batteryGlyphs == nil, "unavailable battery data must not render fake glyphs")

print("system status snapshot tests passed")
}
}
