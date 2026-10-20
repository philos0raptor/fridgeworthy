import Foundation

struct SystemStatusSnapshot: Equatable {
    let timeGlyphs: String
    let timeLabel: String
    let batteryPercentage: Int?

    init(
        date: Date,
        batteryLevel: Float,
        locale: Locale = .current,
        calendar: Calendar = .current
    ) {
        let timeFormatter = DateFormatter()
        timeFormatter.locale = locale
        timeFormatter.calendar = calendar
        timeFormatter.timeZone = calendar.timeZone
        timeFormatter.setLocalizedDateFormatFromTemplate("j:mm")

        timeLabel = timeFormatter.string(from: date)
        timeGlyphs = timeLabel.filter { $0.isNumber || $0 == ":" }

        if (0...1).contains(batteryLevel) {
            batteryPercentage = Int((batteryLevel * 100).rounded())
        } else {
            batteryPercentage = nil
        }
    }

    var batteryGlyphs: String? {
        batteryPercentage.map { "\($0)%" }
    }

    var accessibilityValue: String {
        if let batteryPercentage {
            return "\(timeLabel), \(batteryPercentage)% battery"
        }
        return "\(timeLabel), battery level unavailable"
    }
}
