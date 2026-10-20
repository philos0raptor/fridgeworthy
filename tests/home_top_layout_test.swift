import CoreGraphics
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

@main
enum HomeTopLayoutTests {
    static func main() {
        expect(
            HomeTopLayout.monthTop(safeAreaTop: 59) == 63,
            "Dynamic Island devices should place the month just below the measured safe area"
        )
        expect(
            HomeTopLayout.monthTop(safeAreaTop: 47) == 51,
            "the month position should adapt when a modern device has a shorter top inset"
        )

        print("home top layout tests passed")
    }
}
