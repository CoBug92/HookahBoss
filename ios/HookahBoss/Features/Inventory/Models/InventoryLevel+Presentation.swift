import SwiftUI

extension InventoryLevel {
    var title: String {
        switch self {
        case .plenty:
            L10n.Inventory.Level.plenty
        case .low:
            L10n.Inventory.Level.low
        case .empty:
            L10n.Inventory.Level.empty
        }
    }

    var color: Color {
        switch self {
        case .plenty:
            .green
        case .low:
            .orange
        case .empty:
            .secondary
        }
    }
}
