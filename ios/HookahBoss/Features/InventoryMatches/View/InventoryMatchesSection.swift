import SwiftUI

struct InventoryMatchesSection: View {
    let title: String
    let results: [InventoryMixResult]

    private let columns = [
        GridItem(.flexible(), spacing: Margin.x5),
        GridItem(.flexible(), spacing: Margin.x5),
    ]

    var body: some View {
        if !results.isEmpty {
            VStack(alignment: .leading, spacing: Margin.x6) {
                Text(title)
                    .font(.title2.weight(.semibold))

                LazyVGrid(columns: columns, spacing: Margin.x5) {
                    ForEach(results) { result in
                        InventoryMixResultCard(result: result)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    InventoryMatchesSection(
        title: L10n.Inventory.Results.ready,
        results: [
            InventoryMixResult(
                mix: MixesPreviewData.featured,
                kind: .ready
            ),
        ]
    )
    .padding(Margin.x8)
    .background(AppTheme.background)
}
