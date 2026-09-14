import SwiftUI

struct InventoryMixResultCard: View {
    let result: InventoryMixResult

    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x4) {
            NavigationLink(value: result.mix) {
                MixCardView(mix: result.mix)
            }
            .buttonStyle(.plain)

            if let note = result.note {
                Label(
                    note,
                    systemImage: result.kind == .substitution
                        ? AppSymbol.forward
                        : AppSymbol.remove
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }
        }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    InventoryMixResultCard(
        result: InventoryMixResult(
            mix: MixesPreviewData.featured,
            kind: .substitution,
            note: L10n.Inventory.Sample.substitution
        )
    )
    .frame(width: 180)
    .padding(Margin.x8)
    .background(AppTheme.background)
}
