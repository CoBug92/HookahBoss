import SwiftUI

struct InventoryView: View {
    let items: [InventoryItem]
    let expandedItemID: String?
    let onToggle: (String) -> Void
    let onSelect: (InventoryLevel, String) -> Void
    let onDeletePrivate: (InventoryItem) -> Void

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView(
                    L10n.Inventory.empty,
                    systemImage: AppSymbol.inventoryOutline
                )
            } else {
                List(items) { item in
                    InventoryRow(
                        item: item,
                        isExpanded: expandedItemID == item.id,
                        toggle: { onToggle(item.id) },
                        select: { onSelect($0, item.id) }
                    )
                    .swipeActions {
                        if item.id.hasPrefix(TechnicalString.privateInventoryPrefix) {
                            Button(L10n.Common.delete, role: .destructive) {
                                onDeletePrivate(item)
                            }
                        }
                    }
                    .listRowBackground(AppTheme.card)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle(L10n.Inventory.title)
        .appScreenBackground()
    }
}

// MARK: - Preview

#Preview("Content") {
    NavigationStack {
        InventoryView(
            items: CollectionPreviewData.inventory,
            expandedItemID: nil,
            onToggle: { _ in },
            onSelect: { _, _ in },
            onDeletePrivate: { _ in }
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        InventoryView(
            items: [],
            expandedItemID: nil,
            onToggle: { _ in },
            onSelect: { _, _ in },
            onDeletePrivate: { _ in }
        )
    }
}
