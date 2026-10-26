import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
enum ArtworkCollageLayoutTests {
    static func main() {
        expect(ArtworkCollageLayout.frames(count: 0).isEmpty, "empty input has no tiles")

        let one = ArtworkCollageLayout.frames(count: 1)
        expect(one.count == 1, "one image has one tile")
        expect(one[0].width > 900, "one image gets nearly the full canvas width")
        expect(one[0].minY >= 400, "artwork stays clear of the lock-screen clock")

        let five = ArtworkCollageLayout.frames(count: 5)
        expect(five.count == 5, "every input gets a tile")
        expect(five.allSatisfy { $0.minX >= 0 && $0.minY >= 400 && $0.maxX <= 1170 && $0.maxY <= 2532 }, "all tiles fit the canvas")
        for left in 0..<five.count {
            for right in (left + 1)..<five.count {
                expect(!five[left].intersects(five[right]), "tiles do not overlap")
            }
        }

        let many = ArtworkCollageLayout.frames(count: 300)
        expect(many.count == 300, "large collections retain every piece")
        expect(many.allSatisfy { $0.size.height > 0 && $0.maxY <= 2532 }, "large collections keep positive in-canvas tiles")
        expect(!many[0].intersects(many[2]), "adjacent rows remain separate in large collections")

        print("artwork collage layout tests passed")
    }
}
