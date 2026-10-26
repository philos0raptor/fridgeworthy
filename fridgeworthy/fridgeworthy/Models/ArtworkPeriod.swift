import Foundation

enum ArtworkPeriodKind: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }

    var calendarComponent: Calendar.Component {
        self == .week ? .weekOfYear : .month
    }
}

struct ArtworkPeriod {
    let kind: ArtworkPeriodKind
    let anchor: Date
    let calendar: Calendar

    init(kind: ArtworkPeriodKind, anchor: Date, calendar: Calendar = .current) {
        self.kind = kind
        self.anchor = anchor
        self.calendar = calendar
    }

    private var interval: DateInterval {
        calendar.dateInterval(of: kind.calendarComponent, for: anchor)!
    }

    var start: Date { interval.start }
    var end: Date { interval.end }

    func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }

    func shifted(by amount: Int) -> ArtworkPeriod {
        let newAnchor = calendar.date(byAdding: kind.calendarComponent, value: amount, to: anchor) ?? anchor
        return ArtworkPeriod(kind: kind, anchor: newAnchor, calendar: calendar)
    }
}
