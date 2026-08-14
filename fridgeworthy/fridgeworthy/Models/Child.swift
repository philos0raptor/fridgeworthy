import Foundation
import SwiftData

@Model
final class Child {
    @Attribute(.unique) var id: UUID
    var name: String
    var avatarEmoji: String
    var birthDate: Date?
    var createdAt: Date

    var parent: UserProfile?

    @Relationship(deleteRule: .cascade, inverse: \Artwork.child)
    var artworks: [Artwork] = []

    @Relationship(deleteRule: .cascade, inverse: \Wallpaper.child)
    var wallpapers: [Wallpaper] = []

    /// Formatted age string: "6 months" if under 1, "3 years" if 1+, nil if no birthDate.
    var ageText: String? {
        guard let birthDate else { return nil }
        let components = Calendar.current.dateComponents([.year, .month], from: birthDate, to: Date())
        let years = components.year ?? 0
        let months = components.month ?? 0
        if years < 1 {
            return "\(max(months, 1)) month\(months == 1 ? "" : "s")"
        }
        return "\(years) year\(years == 1 ? "" : "s")"
    }

    /// Age in years, or nil if under 1 or no birthDate.
    var age: Int? {
        guard let birthDate else { return nil }
        let years = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        return years > 0 ? years : nil
    }

    init(
        id: UUID = UUID(),
        name: String,
        avatarEmoji: String = "🎨",
        birthDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.birthDate = birthDate
        self.createdAt = createdAt
    }
}
