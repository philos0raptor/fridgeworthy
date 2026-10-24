import Foundation

struct MonthDay: Equatable {
    let date: Date
    let number: Int
    let isToday: Bool
}

enum MonthCalendar {
    static func days(
        for month: Date,
        calendar: Calendar,
        now: Date = Date()
    ) -> [MonthDay?] {
        guard let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: month)
        ), let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let weekday = calendar.component(.weekday, from: monthStart)
        let leadingCount = (weekday - calendar.firstWeekday + 7) % 7

        var result = Array<MonthDay?>(repeating: nil, count: leadingCount)
        result.reserveCapacity(42)

        for dayNumber in dayRange {
            guard let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: monthStart) else {
                continue
            }
            result.append(MonthDay(
                date: date,
                number: dayNumber,
                isToday: calendar.isDate(date, inSameDayAs: now)
            ))
        }

        while !result.count.isMultiple(of: 7) {
            result.append(nil)
        }
        return result
    }

    static func offset(_ month: Date, by value: Int, calendar: Calendar) -> Date {
        let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: month)
        ) ?? month
        return calendar.date(byAdding: .month, value: value, to: monthStart) ?? monthStart
    }

    static func clampedOffset(
        _ month: Date,
        by value: Int,
        now: Date = Date(),
        calendar: Calendar
    ) -> Date {
        let candidate = offset(month, by: value, calendar: calendar)
        let currentMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ) ?? now
        return candidate > currentMonth ? currentMonth : candidate
    }

    static func isCurrentMonth(
        _ month: Date,
        now: Date = Date(),
        calendar: Calendar
    ) -> Bool {
        calendar.isDate(month, equalTo: now, toGranularity: .month)
    }

    static func dayKey(for date: Date, calendar: Calendar) -> Date {
        calendar.startOfDay(for: date)
    }

    static func selectableYears(
        currentYear: Int,
        earliestYear: Int = 2026
    ) -> ClosedRange<Int> {
        earliestYear...max(earliestYear, currentYear)
    }

    static func selectableMonths(
        year: Int,
        now: Date = Date(),
        calendar: Calendar
    ) -> [Int] {
        let currentYear = calendar.component(.year, from: now)
        guard year <= currentYear else { return [] }

        let finalMonth = year == currentYear
            ? calendar.component(.month, from: now)
            : 12
        return Array(1...finalMonth)
    }
}
