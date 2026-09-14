import SwiftUI

struct HomeView: View {

    // MARK: - Properties

    @Namespace private var mixTransitionNamespace
    @StateObject private var model: HomeViewModel
    private let onFindMix: () -> Void
    private let onInventory: () -> Void
    private let onProfile: () -> Void
    private let makeMixDetailModel: (MixPreview) -> MixDetailViewModel

    // MARK: - Init

    init(
        model: @autoclosure @escaping () -> HomeViewModel,
        onFindMix: @escaping () -> Void = {},
        onInventory: @escaping () -> Void = {},
        onProfile: @escaping () -> Void = {},
        makeMixDetailModel: @escaping (MixPreview) -> MixDetailViewModel
    ) {
        _model = StateObject(wrappedValue: model())
        self.onFindMix = onFindMix
        self.onInventory = onInventory
        self.onProfile = onProfile
        self.makeMixDetailModel = makeMixDetailModel
    }

    // MARK: - Layout

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    switch model.state {
                    case .loading:
                        HomeSkeletonView()
                    case .content:
                        HomeLoadedContentView(
                            mixOfDay: model.mixOfDay,
                            recommendations: model.recommendations,
                            onFindMix: onFindMix,
                            onInventory: onInventory
                        )
                    case .cached:
                        HomeCachedContentView(
                            mixOfDay: model.mixOfDay,
                            recommendations: model.recommendations,
                            onFindMix: onFindMix,
                            onInventory: onInventory,
                            onRetry: retry
                        )
                    case .empty:
                        HomeStatusView(
                            icon: AppSymbol.mixing,
                            title: L10n.Home.Empty.title,
                            message: L10n.Home.Empty.message,
                            actionTitle: L10n.Common.refresh,
                            action: retry
                        )
                    case .failure:
                        HomeStatusView(
                            icon: AppSymbol.retryUnavailable,
                            title: L10n.Home.Error.title,
                            message: L10n.Home.Error.message,
                            actionTitle: L10n.Common.retry,
                            action: retry
                        )
                    }
                }
                .padding(.horizontal, Margin.x9)
                .padding(.top, Margin.x2)
                .padding(.bottom, Margin.x(17))
            }
            .task { await model.appear() }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(L10n.Home.question)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onProfile) {
                        Image(systemName: AppSymbol.profile)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(AppTheme.gold)
                    }
                    .accessibilityLabel(Text(L10n.Home.profile))
                    .accessibilityIdentifier(AccessibilityID.homeLogin)
                }
            }
            .navigationDestination(for: MixPreview.self) { mix in
                MixDetailView(model: makeMixDetailModel(mix))
            }
        }
        .environment(\.mixTransitionNamespace, mixTransitionNamespace)
        .onAppear { model.syncLibraryState() }
        .accessibilityIdentifier("screen.home")
    }

    // MARK: - Private methods

    private func retry() {
        Task {
            await model.refresh(force: true)
        }
    }
}

@MainActor
private func homePreview(content: PreviewPublicCatalogService) -> some View {
    let library = PreviewAuthLibraryService()

    return HomeView(
        model: HomeViewModel(
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
}

// MARK: - Preview

#Preview("Loading") {
    homePreview(
        content: PreviewPublicCatalogService(
            catalogDelay: .seconds(60)
        )
    )
}

#Preview("Content") {
    homePreview(
        content: PreviewPublicCatalogService(
            mixes: HomePreviewData.mixes
        )
    )
}

#Preview("Cached") {
    homePreview(
        content: PreviewPublicCatalogService(
            mixes: HomePreviewData.mixes,
            freshness: .cached
        )
    )
}

#Preview("Empty") {
    homePreview(content: PreviewPublicCatalogService())
}

#Preview("Error") {
    homePreview(
        content: PreviewPublicCatalogService(
            catalogFails: true
        )
    )
}
