import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var supabaseID: String
    var email: String?
    var displayName: String?
    var relationship: UserRelationship?
    var subscriptionTier: SubscriptionTier
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Child.parent)
    var children: [Child] = []

    /// Greeting text for Home screen: relationship label, custom name, or fallback.
    var greeting: String {
        if let relationship, relationship != .other {
            return relationship.displayLabel
        }
        if let displayName, !displayName.isEmpty {
            return displayName
        }
        return "there"
    }

    init(
        id: UUID = UUID(),
        supabaseID: String,
        email: String? = nil,
        displayName: String? = nil,
        relationship: UserRelationship? = nil,
        subscriptionTier: SubscriptionTier = .free,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.supabaseID = supabaseID
        self.email = email
        self.displayName = displayName
        self.relationship = relationship
        self.subscriptionTier = subscriptionTier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum UserRelationship: String, Codable, CaseIterable {
    case mom, dad, grandma, grandpa, auntie, uncle, nanny, other

    var displayLabel: String {
        switch self {
        case .mom: "Mom"
        case .dad: "Dad"
        case .grandma: "Grandma"
        case .grandpa: "Grandpa"
        case .auntie: "Auntie"
        case .uncle: "Uncle"
        case .nanny: "Nanny"
        case .other: "Other"
        }
    }

    var emoji: String {
        switch self {
        case .mom: "👩"
        case .dad: "👨"
        case .grandma: "👵"
        case .grandpa: "👴"
        case .auntie: "👩‍🦰"
        case .uncle: "👨‍🦱"
        case .nanny: "🧑‍🍼"
        case .other: "✏️"
        }
    }
}

enum SubscriptionTier: String, Codable {
    case free
    case pro
}
