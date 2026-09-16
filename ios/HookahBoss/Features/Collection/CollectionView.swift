import SwiftUI

struct CollectionView: View {

    // MARK: - Properties

    @EnvironmentObject private var navigation: AppNavigation
    @Namespace private var mixTransitionNamespace
    @StateObject private var model: CollectionViewModel
    let makeMixDetail: (MixPreview) -> MixDetailViewModel
    let makeMatches: () -> InventoryMatchesViewModel
    let adminView: () -> AnyView

    // MARK: - Init

    init(
        model: @autoclosure @escaping () -> CollectionViewModel,
        makeMixDetail: @escaping (MixPreview) -> MixDetailViewModel,
        makeMatches: @escaping () -> InventoryMatchesViewModel,
        adminView: @escaping () -> AnyView
    ) {
        _model = StateObject(wrappedValue: model())
        self.makeMixDetail = makeMixDetail
        self.makeMatches = makeMatches
        self.adminView = adminView
    }

    // MARK: - Layout

    var body: some View {
        switch model.state {
        case .loading:
            CollectionSkeletonView()
                .onAppear { model.appear() }
        case .signedOut:
            SignedOutCollectionView(model: model)
                .onAppear { model.appear() }
        case .content:
            accountContent
                .onAppear { model.appear() }
        }
    }

    private var accountContent: some View {
        NavigationStack(path: $navigation.collectionPath) {
            List {
                CollectionOverviewSection(
                    favoritesCount: model.favoriteMixIDs.count,
                    personalMixesCount: model.personalMixes.count
                )

                CollectionPersonalMixesSection(mixes: model.personalMixes)

                CollectionInventorySection(
                    items: model.inventory,
                    expandedItemID: model.expandedItemID,
                    onToggle: model.toggleExpanded,
                    onSelect: model.setLevel,
                    onAdd: { model.showAddInventory = true }
                )

                CollectionMatchesSection(makeMatches: makeMatches)

                if model.isAdmin {
                    CollectionAdminSection {
                        model.showAdmin = true
                    }
                }
            }
            .scrollIndicators(.hidden)
            .listStyle(.insetGrouped)
            .navigationTitle(L10n.Tab.collection)
            .appScreenBackground()
            .collectionPresentations(
                model: model,
                adminView: adminView
            )
            .toolbar {
                Button {
                    model.showSettings = true
                } label: {
                    Image(systemName: AppSymbol.profile)
                }
                .accessibilityLabel(Text(L10n.Account.settings))
            }
            .navigationDestination(for: MixPreview.self) { mix in
                MixDetailView(model: makeMixDetail(mix))
            }
            .navigationDestination(for: CollectionDestination.self) { destination in
                destinationView(destination)
            }
        }
        .environment(\.mixTransitionNamespace, mixTransitionNamespace)
    }

    @ViewBuilder
    private func destinationView(_ destination: CollectionDestination) -> some View {
        switch destination {
        case .favorites:
            FavoritesView(
                model: model,
                title: L10n.Collection.favorites
            )
        case .personal:
            PersonalMixesView(mixes: model.personalMixes)
        case .inventory:
            InventoryView(
                items: model.inventory,
                expandedItemID: model.expandedItemID,
                onToggle: model.toggleExpanded,
                onSelect: model.setLevel,
                onDeletePrivate: model.deletePrivate
            )
        case .inventoryResults:
            InventoryMatchesView(model: makeMatches())
        }
    }
}

@MainActor
private func collectionPreview(
    snapshot: CollectionSnapshot,
    delay: Duration? = nil
) -> some View {
    let content = PreviewPublicCatalogService(mixes: MixesPreviewData.catalog)
    let auth = PreviewAuthLibraryService()

    return CollectionView(
        model: CollectionViewModel(
            service: CollectionPreviewService(
                value: snapshot,
                delay: delay
            ),
            library: auth
        ),
        makeMixDetail: { mix in
            MixDetailViewModel(
                mix: mix,
                content: content,
                auth: auth
            )
        },
        makeMatches: {
            InventoryMatchesViewModel(
                service: nil,
                catalog: snapshot.catalogMixes,
                products: snapshot.products
            )
        },
        adminView: {
            AnyView(EmptyView())
        }
    )
    .environmentObject(AppNavigation())
}

// MARK: - Preview

#Preview("Loading") {
    collectionPreview(
        snapshot: CollectionPreviewData.content,
        delay: .seconds(60)
    )
}

#Preview("Signed out") {
    collectionPreview(snapshot: CollectionPreviewData.signedOut)
}

#Preview("Content") {
    collectionPreview(snapshot: CollectionPreviewData.content)
}

#Preview("Admin") {
    collectionPreview(snapshot: CollectionPreviewData.admin)
}
