import Foundation

struct InventoryMixResult: Identifiable, Equatable {
    enum Kind: String, Equatable {
        case ready
        case substitution
        case missing
    }

    let mix: MixPreview
    let kind: Kind
    var note: String?

    var id: UUID {
        mix.id
    }
}
