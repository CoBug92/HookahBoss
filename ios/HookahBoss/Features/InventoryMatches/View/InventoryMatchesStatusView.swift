import SwiftUI

struct InventoryMatchesStatusView: View {
    let title: String
    let message: String
    let showsRetry: Bool
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: AppSymbol.inventoryOutline)
        } description: {
            Text(message)
        } actions: {
            if showsRetry {
                Button(L10n.Common.retry, action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.gold)
            }
        }
        .padding(.vertical, Margin.x(20))
    }
}

// MARK: - Preview

#Preview("Empty", traits: .sizeThatFitsLayout) {
    InventoryMatchesStatusView(
        title: L10n.Inventory.Results.Empty.title,
        message: L10n.Inventory.Results.Empty.message,
        showsRetry: false,
        onRetry: {}
    )
}

#Preview("Failure", traits: .sizeThatFitsLayout) {
    InventoryMatchesStatusView(
        title: L10n.Content.Error.title,
        message: L10n.Content.Error.network,
        showsRetry: true,
        onRetry: {}
    )
}
