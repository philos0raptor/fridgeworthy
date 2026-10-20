import Foundation

@main
struct MonthGridLayoutTests {
    static func main() {
        testFiveRowMonthExpandsToFillTheCalendarBand()
        testSixRowMonthFitsTheSameCalendarBand()
        print("month grid layout tests passed")
    }

    private static func testFiveRowMonthExpandsToFillTheCalendarBand() {
        let spacing = MonthGridLayout.rowSpacing(
            rowCount: 5,
            targetHeight: 430,
            cellHeight: 44
        )

        precondition(abs(spacing - 52.5) < 0.001, "five-row months should spread toward the bottom navigation")
    }

    private static func testSixRowMonthFitsTheSameCalendarBand() {
        let spacing = MonthGridLayout.rowSpacing(
            rowCount: 6,
            targetHeight: 430,
            cellHeight: 44
        )

        precondition(abs(spacing - 33.2) < 0.001, "six-row months should fit the same vertical calendar band")
    }
}
