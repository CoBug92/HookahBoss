import Foundation

enum InventoryProjection {
    static func overlay(
        levels: [UUID: InventoryLevel],
        pending: [InventoryMutation]
    ) -> [UUID: InventoryLevel] {
        var result = levels
        for mutation in pending {
            if let id = mutation.productId {
                result[id] = mutation.level
            }
        }
        return result
    }
}
