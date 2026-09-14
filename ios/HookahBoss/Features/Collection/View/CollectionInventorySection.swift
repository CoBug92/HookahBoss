import SwiftUI

struct CollectionInventorySection: View {
    let items: [InventoryItem]
    let expandedItemID: String?
    let onToggle: (String) -> Void
    let onSelect: (InventoryLevel, String) -> Void
    let onAdd: () -> Void

    var body: some View {
        Section {
            if items.isEmpty {
                Label(
                    L10n.Inventory.empty,
                    systemImage: AppSymbol.inventoryOutline
                )
                .foregroundStyle(.secondary)
            }

            ForEach(items.prefix(5)) { item in
                InventoryRow(
                    item: item,
                    isExpanded: expandedItemID == item.id,
                    toggle: {
                        withAnimation(.snappy) {
                            onToggle(item.id)
                        }
                    },
                    select: { level in
                        withAnimation(.snappy) {
                            onSelect(level, item.id)
                        }
                    }
                )
            }

            Button(
                L10n.Inventory.add,
                systemImage: AppSymbol.create,
                action: onAdd
            )

            NavigationLink(
                L10n.Common.all,
                value: CollectionDestination.inventory
            )
        } header: {
            Text(L10n.Inventory.title)
        } footer: {
            Text(L10n.Inventory.hint)
        }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    List {
        CollectionInventorySection(
            items: CollectionPreviewData.inventory,
            expandedItemID: CollectionPreviewData.inventory.first?.id,
            onToggle: { _ in },
            onSelect: { _, _ in },
            onAdd: {}
        )
    }
}
