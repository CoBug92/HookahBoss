import Foundation

struct LibraryMutation: Codable, Equatable, Identifiable {
    enum Kind: String, Codable {
        case favorite
        case rating
    }

    let id: UUID
    let kind: Kind
    let mixId: UUID
    let value: Int?
}
