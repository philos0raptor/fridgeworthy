import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
enum ArtworkTimestampTests {
    static func main() {
        let fractional = ArtworkTimestamp.parse("2026-10-20T12:34:56.123456+00:00")
        let whole = ArtworkTimestamp.parse("2026-10-20T12:34:56Z")
        expect(fractional != nil, "fractional Supabase timestamps must parse")
        expect(whole != nil, "whole-second timestamps must still parse")
        expect(abs(fractional!.timeIntervalSince(whole!) - 0.123456) < 0.001, "fractional seconds retain their date")
        expect(ArtworkTimestamp.parse("not a date") == nil, "invalid timestamps cannot become current artwork")
        print("artwork timestamp tests passed")
    }
}
