import SwiftUI

struct CollectionMatchesSection: View {
    let makeMatches: () -> InventoryMatchesViewModel

    var body: some View {
        Section {
            NavigationLink(L10n.Inventory.findMixes) {
                InventoryMatchesView(model: makeMatches())
            }
        }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    List {
        CollectionMatchesSection {
            InventoryMatchesViewModel(
                service: nil,
                catalog: [],
                products: []
            )
        }
    }
}
