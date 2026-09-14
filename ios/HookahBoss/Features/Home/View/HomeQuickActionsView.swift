import SwiftUI

struct HomeQuickActionsView: View {
    let onFindMix: () -> Void
    let onInventory: () -> Void

    var body: some View {
        HStack(spacing: Margin.x5) {
            HomeQuickActionView(
                title: L10n.Home.findMix,
                icon: AppSymbol.filters,
                emphasized: true,
                action: onFindMix
            )
            .accessibilityIdentifier(AccessibilityID.homeFindMix)
            HomeQuickActionView(
                title: L10n.Inventory.findMixes,
                icon: AppSymbol.inventory,
                emphasized: false,
                action: onInventory
            )
        }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    HomeQuickActionsView(
        onFindMix: {},
        onInventory: {}
    )
    .padding(Margin.x9)
    .background(AppTheme.background)
}
