import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
enum ArtworkPeriodTests {
    static func main() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2

        func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day))!
        }

        let week = ArtworkPeriod(kind: .week, anchor: date(2026, 10, 28), calendar: calendar)
        expect(week.start == date(2026, 10, 26), "week must start on Monday")
        expect(week.end == date(2026, 11, 2), "week must end at next Monday")
        expect(week.contains(date(2026, 10, 26)), "week includes start")
        expect(!week.contains(date(2026, 11, 2)), "week excludes end")

        let month = ArtworkPeriod(kind: .month, anchor: date(2026, 10, 28), calendar: calendar)
        expect(month.start == date(2026, 10, 1), "month starts on first day")
        expect(month.end == date(2026, 11, 1), "month ends at next first day")
        expect(month.contains(date(2026, 10, 31)), "month includes last day")
        expect(!month.contains(date(2026, 11, 1)), "month excludes next month")

        let previous = ArtworkPeriod(kind: .week, anchor: date(2026, 10, 21), calendar: calendar)
        expect(previous.end == week.start, "adjacent weeks meet without overlap")
        expect(!previous.contains(week.start), "boundary belongs only to new week")

        print("artwork period tests passed")
    }
}
