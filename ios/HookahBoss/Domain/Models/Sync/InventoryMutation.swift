import Foundation

struct InventoryMutation: Codable, Equatable {
    let productId: UUID?
    let privateProductId: UUID?
    let level: InventoryLevel

    var key: String {
        productId?.uuidString ?? "private:\(privateProductId?.uuidString ?? "")"
    }
}
