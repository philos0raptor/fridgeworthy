import Foundation

private func expect(
    _ condition: @autoclosure () -> Bool,
    _ message: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard condition() else {
        fputs("FAIL: \(message) (\(file):\(line))\n", stderr)
        exit(1)
    }
}

private var calendar: Calendar = {
    var value = Calendar(identifier: .gregorian)
    value.timeZone = TimeZone(secondsFromGMT: 0)!
    value.locale = Locale(identifier: "en_US_POSIX")
    value.firstWeekday = 2 // Monday
    return value
}()

private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
    calendar.date(from: DateComponents(
        calendar: calendar,
        timeZone: calendar.timeZone,
        year: year,
        month: month,
        day: day,
        hour: hour
    ))!
}

@main
enum MonthCalendarTests {
static func main() {
let october = MonthCalendar.days(
    for: date(2026, 10, 18),
    calendar: calendar,
    now: date(2026, 10, 17)
)
expect(october.count == 35, "October 2026 should pad to five full weeks")
expect(october.prefix(3).allSatisfy { $0 == nil }, "Monday-first October should have three leading cells")
expect(october[3]?.number == 1, "October 1 should occupy the fourth cell")
expect(october.compactMap { $0 }.count == 31, "October should contain 31 numbered days")
expect(october.compactMap { $0 }.first(where: { $0.number == 17 })?.isToday == true, "Fixed now should mark October 17 as today")

let leapFebruary = MonthCalendar.days(
    for: date(2028, 2, 14),
    calendar: calendar,
    now: date(2028, 1, 1)
)
expect(leapFebruary.compactMap { $0 }.count == 29, "February 2028 should contain leap day")
expect(leapFebruary.count.isMultiple(of: 7), "Every month grid should contain complete weeks")

let january = MonthCalendar.offset(date(2026, 12, 15), by: 1, calendar: calendar)
let januaryComponents = calendar.dateComponents([.year, .month, .day], from: january)
expect(januaryComponents.year == 2027 && januaryComponents.month == 1 && januaryComponents.day == 1, "Month offset should cross year boundaries and normalize to day one")

let currentMonth = date(2026, 10, 1)
let nextMonthFromCurrent = MonthCalendar.clampedOffset(
    currentMonth,
    by: 1,
    now: date(2026, 10, 23),
    calendar: calendar
)
expect(calendar.isDate(nextMonthFromCurrent, equalTo: currentMonth, toGranularity: .month), "forward navigation from the current month should stay in the current month")
let previousMonth = MonthCalendar.clampedOffset(
    currentMonth,
    by: -1,
    now: date(2026, 10, 23),
    calendar: calendar
)
expect(calendar.component(.month, from: previousMonth) == 9, "backward navigation from the current month should still reach the previous month")
let nextMonthFromPast = MonthCalendar.clampedOffset(
    date(2026, 9, 1),
    by: 2,
    now: date(2026, 10, 23),
    calendar: calendar
)
expect(calendar.isDate(nextMonthFromPast, equalTo: currentMonth, toGranularity: .month), "past-month navigation should clamp at the current month")

expect(
    MonthCalendar.isCurrentMonth(date(2026, 10, 1), now: date(2026, 10, 31), calendar: calendar),
    "Dates in the same month should compare as current"
)
expect(
    !MonthCalendar.isCurrentMonth(date(2026, 9, 30), now: date(2026, 10, 1), calendar: calendar),
    "Dates in different months should not compare as current"
)

let normalized = MonthCalendar.dayKey(for: date(2026, 10, 17, hour: 21), calendar: calendar)
expect(calendar.component(.hour, from: normalized) == 0, "Day keys should normalize to calendar midnight")

let launchYearRange = MonthCalendar.selectableYears(currentYear: 2026)
expect(launchYearRange.lowerBound == 2026, "The month picker must not offer pre-launch years")
expect(launchYearRange.upperBound == 2026, "The month picker must not offer future years")

let laterYearRange = MonthCalendar.selectableYears(currentYear: 2030)
expect(laterYearRange.lowerBound == 2026, "The launch year must remain available as time advances")
expect(laterYearRange.upperBound == 2030, "The month picker must stop at the current year")

let currentYearMonths = MonthCalendar.selectableMonths(
    year: 2026,
    now: date(2026, 10, 19),
    calendar: calendar
)
expect(currentYearMonths == Array(1...10), "The current year must hide future months")

let pastYearMonths = MonthCalendar.selectableMonths(
    year: 2028,
    now: date(2030, 4, 2),
    calendar: calendar
)
expect(pastYearMonths == Array(1...12), "Past years should offer every month")

let futureYearMonths = MonthCalendar.selectableMonths(
    year: 2031,
    now: date(2030, 4, 2),
    calendar: calendar
)
expect(futureYearMonths.isEmpty, "Future years must not offer any months")

print("month calendar tests passed")
}
}
