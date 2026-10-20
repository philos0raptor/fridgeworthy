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
enum DailyMemoryNavigationTests {
    static func main() {
        expect(DailyMemoryNavigation.wrappedIndex(0, delta: 1, count: 0) == 0, "an empty stack must stay at index zero")
        expect(DailyMemoryNavigation.wrappedIndex(0, delta: 1, count: 1) == 0, "a single card must stay selected")
        expect(DailyMemoryNavigation.wrappedIndex(0, delta: 1, count: 2) == 1, "a forward swipe should select the second card")
        expect(DailyMemoryNavigation.wrappedIndex(1, delta: 1, count: 2) == 0, "the last card should wrap to the first")
        expect(DailyMemoryNavigation.wrappedIndex(0, delta: -1, count: 2) == 1, "a backward swipe from the first card should wrap to the last")
        expect(DailyMemoryNavigation.wrappedIndex(2, delta: 1, count: 3) == 0, "three-card stacks should wrap forward")
        expect(DailyMemoryNavigation.wrappedIndex(0, delta: -1, count: 3) == 2, "three-card stacks should wrap backward")

        let today = date(2026, 10, 20)
        let yesterday = DailyMemoryNavigation.dayOffset(today, by: -1, calendar: calendar)
        expect(calendar.isDate(yesterday, inSameDayAs: date(2026, 10, 19)), "leftward day navigation should move to the previous date")
        expect(DailyMemoryNavigation.isToday(today, now: today, calendar: calendar), "today detection should use the injected calendar")
        expect(!DailyMemoryNavigation.isToday(yesterday, now: today, calendar: calendar), "older dates must not report as today")

        let fromYesterday = DailyMemoryNavigation.clampedTowardToday(yesterday, by: 1, now: today, calendar: calendar)
        expect(calendar.isDate(fromYesterday, inSameDayAs: today), "rightward navigation should return an older day to today")

        let beyondToday = DailyMemoryNavigation.clampedTowardToday(today, by: 1, now: today, calendar: calendar)
        expect(calendar.isDate(beyondToday, inSameDayAs: today), "rightward navigation must not move into the future")

        print("daily memory navigation tests passed")
    }
}
