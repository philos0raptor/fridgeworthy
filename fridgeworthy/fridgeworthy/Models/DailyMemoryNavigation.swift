import Foundation

enum DailyMemoryNavigation {
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
}
