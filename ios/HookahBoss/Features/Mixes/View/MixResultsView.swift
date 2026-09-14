import SwiftUI

struct MixResultsView: View {

    // MARK: - Properties

    @ObservedObject var model: MixCatalogViewModel
    @State private var filters = false

    // MARK: - Layout

    var body: some View {
        ScrollView {
            if model.ideal.isEmpty && model.possible.isEmpty {
                AppEmptyState(
                    icon: AppSymbol.filters,
                    title: L10n.Filters.Empty.title,
                    message: L10n.Filters.Empty.message
                )
                .padding(Margin.x9)
            } else {
                LazyVStack(
                    alignment: .leading,
                    spacing: Margin.x(14)
                ) {
                    MixResultSectionView(
                        title: L10n.Results.ideal,
                        mixes: model.ideal
                    )
                    MixResultSectionView(
                        title: L10n.Results.possible,
                        mixes: model.possible
                    )
                }
                .padding(Margin.x8)
            }
        }
        .background(AppTheme.background)
        .navigationTitle(L10n.Results.title)
        .accessibilityIdentifier("screen.mixResults")
        .toolbar {
            Button(L10n.Results.edit) {
                filters = true
            }
        }
        .sheet(isPresented: $filters) {
            MixFilterView(
                model: MixFilterViewModel(
                    catalog: model.catalog,
                    filter: model.filter
                ),
                onApply: model.apply
            )
        }
    }
}

// MARK: - Preview

#Preview {
    let content = PreviewPublicCatalogService(mixes: MixesPreviewData.catalog)
    let model = MixCatalogViewModel(
        content: content,
        library: PreviewAuthLibraryService()
    )

    NavigationStack {
        MixResultsView(model: model)
            .task { await model.appear() }
    }
}
