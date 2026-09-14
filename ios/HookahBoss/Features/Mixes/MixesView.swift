import SwiftUI
import UIKit

struct MixesView: View {

    // MARK: - Properties

    @EnvironmentObject private var navigation: AppNavigation
    @Namespace private var mixTransitionNamespace
    @StateObject private var model: MixCatalogViewModel
    @State private var filters = false
    @State private var results = false
    @State private var handledFiltersRequest = 0
    private let makeMixDetailModel: (MixPreview) -> MixDetailViewModel

    // MARK: - Computed properties

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            MixesSkeletonView()
        case .content:
            MixesLoadedContentView(mixes: model.visibleMixes)
        case .cached:
            LazyVStack(spacing: Margin.x6) {
                MixesCachedNoticeView(onRetry: retry)
                MixesLoadedContentView(mixes: model.visibleMixes)
            }
        case .empty:
            MixesStatusView(
                icon: AppSymbol.grid,
                title: L10n.Mixes.Empty.title,
                message: L10n.Mixes.Empty.message,
                actionTitle: L10n.Common.refresh,
                action: retry
            )
        case .failure:
            MixesStatusView(
                icon: AppSymbol.retryUnavailable,
                title: L10n.Mixes.Error.title,
                message: L10n.Mixes.Error.message,
                actionTitle: L10n.Common.retry,
                action: retry
            )
        }
    }

    // MARK: - Init

    init(
        model: @autoclosure @escaping () -> MixCatalogViewModel,
        makeMixDetailModel: @escaping (MixPreview) -> MixDetailViewModel
    ) {
        _model = StateObject(wrappedValue: model())
        self.makeMixDetailModel = makeMixDetailModel
    }

    // MARK: - Layout

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding(.horizontal, Margin.x8)
                    .padding(.top, Margin.x2)
                    .padding(.bottom, Margin.x(15))
            }
            .scrollIndicators(.hidden)
            .background(AppTheme.background)
            .navigationTitle(L10n.Tab.mixes)
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $model.search,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: L10n.Mix.search
            )
            .scrollDismissesKeyboard(.immediately)
            .simultaneousGesture(TapGesture().onEnded { dismissKeyboard() })
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        filters = true
                    } label: {
                        Image(systemName: AppSymbol.filters)
                    }
                    .accessibilityLabel(Text(L10n.Filters.title))
                    .accessibilityIdentifier(AccessibilityID.mixFilters)
                }
            }
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .refreshable { await model.refresh() }
            .task { await model.appear() }
            .onAppear { model.syncLibraryState() }
            .onAppear { presentRequestedFilters() }
            .onChange(of: navigation.mixFiltersRequest) { _, _ in presentRequestedFilters() }
            .sheet(isPresented: $filters) {
                MixFilterView(
                    model: MixFilterViewModel(
                        catalog: model.catalog,
                        filter: model.filter
                    )
                ) {
                    model.apply($0)
                    results = true
                }
            }
            .navigationDestination(isPresented: $results) {
                MixResultsView(model: model)
            }
            .navigationDestination(for: MixPreview.self) { mix in
                MixDetailView(model: makeMixDetailModel(mix))
            }
        }
        .environment(\.mixTransitionNamespace, mixTransitionNamespace)
    }

    // MARK: - Private methods

    private func presentRequestedFilters() {
        guard navigation.mixFiltersRequest > handledFiltersRequest else { return }
        handledFiltersRequest = navigation.mixFiltersRequest
        filters = true
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func retry() {
        Task {
            await model.refresh()
        }
    }
}

@MainActor
private func mixesPreview(content: PreviewPublicCatalogService) -> some View {
    let library = PreviewAuthLibraryService()

    return MixesView(
        model: MixCatalogViewModel(
            content: content,
            library: library
        ),
        makeMixDetailModel: { mix in
            MixDetailViewModel(
                mix: mix,
                content: content,
                auth: library
            )
        }
    )
    .environmentObject(AppNavigation())
}

// MARK: - Preview

#Preview("Loading") {
    mixesPreview(
        content: PreviewPublicCatalogService(
            catalogDelay: .seconds(60)
        )
    )
}

#Preview("Content") {
    mixesPreview(
        content: PreviewPublicCatalogService(
            mixes: MixesPreviewData.catalog
        )
    )
}

#Preview("Cached") {
    mixesPreview(
        content: PreviewPublicCatalogService(
            mixes: MixesPreviewData.catalog,
            freshness: .cached
        )
    )
}

#Preview("Empty") {
    mixesPreview(content: PreviewPublicCatalogService())
}

#Preview("Error") {
    mixesPreview(
        content: PreviewPublicCatalogService(
            catalogFails: true
        )
    )
}
