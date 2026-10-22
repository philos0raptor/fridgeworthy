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
        expect(calendar.isDate(yesterday, inSameDayAs: date(2026, 10, 19)), "a negative day offset should move to the previous date")
        expect(DailyMemoryNavigation.isToday(today, now: today, calendar: calendar), "today detection should use the injected calendar")
        expect(!DailyMemoryNavigation.isToday(yesterday, now: today, calendar: calendar), "older dates must not report as today")
        expect(
            calendar.isDate(
                DailyMemoryNavigation.addArtworkTargetDate(
                    isViewingMemory: true,
                    displayedDate: yesterday,
                    now: today
                ),
                inSameDayAs: yesterday
            ),
            "adding from an entry must target the date currently being viewed"
        )
        expect(
            calendar.isDate(
                DailyMemoryNavigation.addArtworkTargetDate(
                    isViewingMemory: false,
                    displayedDate: yesterday,
                    now: today
                ),
                inSameDayAs: today
            ),
            "adding from outside an entry must default to today"
        )

        expect(
            DailyMemoryNavigation.dayOffsetForSwipe(translationWidth: 80) == -1,
            "a rightward swipe should reveal the previous day"
        )
        expect(
            DailyMemoryNavigation.dayOffsetForSwipe(translationWidth: -80) == 1,
            "a leftward swipe should move back toward today"
        )

        expect(
            DailyMemoryNavigation.showsBottomNavigation(isNoteFocused: false),
            "the bottom navigation should show when the note is not focused"
        )
        expect(
            !DailyMemoryNavigation.showsBottomNavigation(isNoteFocused: true),
            "the bottom navigation should hide while the note owns keyboard focus"
        )

        let fromYesterday = DailyMemoryNavigation.clampedTowardToday(yesterday, by: 1, now: today, calendar: calendar)
        expect(calendar.isDate(fromYesterday, inSameDayAs: today), "a positive day offset should return an older day to today")

        let beyondToday = DailyMemoryNavigation.clampedTowardToday(today, by: 1, now: today, calendar: calendar)
        expect(calendar.isDate(beyondToday, inSameDayAs: today), "positive day offsets must not move into the future")

        let twoDaysAgo = date(2026, 10, 18)
        expect(
            !DailyMemoryNavigation.showsTodayShortcut(for: today, now: today, calendar: calendar),
            "the Today shortcut must stay hidden on the current day"
        )
        expect(
            !DailyMemoryNavigation.showsTodayShortcut(for: yesterday, now: today, calendar: calendar),
            "the Today shortcut must stay hidden when Today is one navigation step away"
        )
        expect(
            DailyMemoryNavigation.showsTodayShortcut(for: twoDaysAgo, now: today, calendar: calendar),
            "the Today shortcut must appear when the selected date is two days behind"
        )

        let railDates = DailyMemoryNavigation.dateRailDates(now: today, calendar: calendar)
        expect(railDates.count == 293, "the date rail should contain every day from January 1, 2026 through October 20, 2026")
        expect(
            calendar.isDate(railDates.first!, inSameDayAs: date(2026, 1, 1)),
            "the date rail must begin at the app's first supported date"
        )
        expect(
            calendar.isDate(railDates.last!, inSameDayAs: today),
            "the date rail must end at Today without exposing future dates"
        )

        let datesWithEntries: Set<Date> = [calendar.startOfDay(for: yesterday)]
        expect(
            DailyMemoryNavigation.hasEntry(on: yesterday, in: datesWithEntries, calendar: calendar),
            "a date with a saved entry should be marked in the mini rail"
        )
        expect(
            !DailyMemoryNavigation.hasEntry(on: today, in: datesWithEntries, calendar: calendar),
            "Today should not receive a marker unless it has an entry"
        )

        print("daily memory navigation tests passed")
    }
}
