import SwiftUI

struct InventoryMatchesView: View {

    // MARK: - Properties

    @StateObject private var model: InventoryMatchesViewModel

    // MARK: - Init

    init(model: @autoclosure @escaping () -> InventoryMatchesViewModel) {
        _model = StateObject(wrappedValue: model())
    }

    // MARK: - Layout

    var body: some View {
        ScrollView {
            switch model.state {
            case .loading:
                InventoryMatchesSkeletonView()
            case .failure:
                InventoryMatchesStatusView(
                    title: L10n.Content.Error.title,
                    message: L10n.Content.Error.network,
                    showsRetry: true,
                    onRetry: { model.retry() }
                )
            case .empty:
                InventoryMatchesStatusView(
                    title: L10n.Inventory.Results.Empty.title,
                    message: L10n.Inventory.Results.Empty.message,
                    showsRetry: false,
                    onRetry: {}
                )
            case .content:
                results
            }
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
        .navigationTitle(L10n.Inventory.Results.title)
        .onAppear {
            model.appear()
        }
    }

    private var results: some View {
        LazyVStack(alignment: .leading, spacing: Margin.x(12)) {
            InventoryMatchesSection(
                title: L10n.Inventory.Results.ready,
                results: model.ready
            )
            InventoryMatchesSection(
                title: L10n.Inventory.Results.substitution,
                results: model.substitutions
            )
            InventoryMatchesSection(
                title: L10n.Inventory.Results.missing,
                results: model.missing
            )
        }
        .padding(Margin.x8)
    }
}

@MainActor
private func inventoryMatchesPreview(
    service: (any InventoryMatchServing)?
) -> some View {
    NavigationStack {
        InventoryMatchesView(
            model: InventoryMatchesViewModel(
                service: service,
                catalog: MixesPreviewData.catalog,
                products: []
            )
        )
    }
}

// MARK: - Preview

#Preview("Loading") {
    inventoryMatchesPreview(
        service: InventoryMatchesPreviewService(
            delay: .seconds(60)
        )
    )
}

#Preview("Content") {
    inventoryMatchesPreview(
        service: InventoryMatchesPreviewService(
            values: [
                InventoryMatchDTO(
                    mixId: MixesPreviewData.featured.id,
                    kind: "ready",
                    missingFlavor: nil,
                    sourceProductId: nil,
                    substituteProductId: nil
                ),
                InventoryMatchDTO(
                    mixId: MixesPreviewData.alternative.id,
                    kind: "missing",
                    missingFlavor: "Bergamot",
                    sourceProductId: nil,
                    substituteProductId: nil
                ),
            ]
        )
    )
}

#Preview("Empty") {
    inventoryMatchesPreview(
        service: InventoryMatchesPreviewService()
    )
}

#Preview("Failure") {
    inventoryMatchesPreview(service: nil)
}
