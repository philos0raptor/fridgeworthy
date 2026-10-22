import Foundation

enum DailyMemoryNavigation {
    private static let firstSupportedYear = 2026

    static func dayOffsetForSwipe(translationWidth: CGFloat) -> Int {
        translationWidth > 0 ? -1 : 1
    }

    static func showsBottomNavigation(isNoteFocused: Bool) -> Bool {
        !isNoteFocused
    }

    static func wrappedIndex(_ index: Int, delta: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return (index + delta % count + count) % count
    }

    static func dayOffset(_ date: Date, by value: Int, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: value, to: date) ?? date
    }

    static func clampedTowardToday(
        _ date: Date,
        by value: Int,
        now: Date = Date(),
        calendar: Calendar
    ) -> Date {
        let candidate = dayOffset(date, by: value, calendar: calendar)
        return calendar.compare(candidate, to: now, toGranularity: .day) == .orderedDescending
            ? now
            : candidate
    }

    static func isToday(_ date: Date, now: Date = Date(), calendar: Calendar) -> Bool {
        calendar.isDate(date, inSameDayAs: now)
    }

    static func hasEntry(on date: Date, in entryDates: Set<Date>, calendar: Calendar) -> Bool {
        entryDates.contains(calendar.startOfDay(for: date))
    }

    static func addArtworkTargetDate(
        isViewingMemory: Bool,
        displayedDate: Date,
        now: Date = Date()
    ) -> Date {
        isViewingMemory ? displayedDate : now
    }

    static func showsTodayShortcut(
        for date: Date,
        now: Date = Date(),
        calendar: Calendar
    ) -> Bool {
        let selectedDay = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: now)
        let distance = calendar.dateComponents([.day], from: selectedDay, to: today).day ?? 0
        return distance >= 2
    }

    static func dateRailDates(now: Date = Date(), calendar: Calendar) -> [Date] {
        let today = calendar.startOfDay(for: now)
        guard let firstSupportedDate = calendar.date(
            from: DateComponents(year: firstSupportedYear, month: 1, day: 1)
        ), firstSupportedDate <= today else {
            return [today]
        }

        let dayCount = calendar.dateComponents(
            [.day],
            from: firstSupportedDate,
            to: today
        ).day ?? 0

        return (0...dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: firstSupportedDate)
        }
    }
}
