import SwiftUI

struct RootView: View {

    // MARK: - Properties

    @StateObject private var auth = AuthRuntime()
    @StateObject private var navigation = AppNavigation()
    @StateObject private var workspace = AccountWorkspace()
    @StateObject private var publicContent = PublicContentStore()
    @State private var previousSelection: AppTab = .home
    @State private var isCreatePresented = false

    // MARK: - Layout

    var body: some View {
        TabView(selection: $navigation.tab) {
            homeTab
            mixesTab
            createTab
            articlesTab
            collectionTab
        }
        .tint(AppTheme.gold)
        .toolbarBackground(AppTheme.card, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onChange(of: navigation.tab, handleTabChange)
        .fullScreenCover(isPresented: $isCreatePresented) {
            createMixView
        }
        .task {
            workspace.activate(accountId: auth.accountId)
        }
        .onChange(of: auth.accountId) { _, accountId in
            workspace.activate(accountId: accountId)
        }
        .environmentObject(auth)
        .environmentObject(navigation)
        .modifier(
            AuthGateSheet(
                gate: auth.gate,
                authenticateIdentityToken: authenticate
            )
        )
    }

    private var homeTab: some View {
        HomeView(
            model: HomeViewModel(
                content: publicContent,
                library: auth
            ),
            onFindMix: { navigation.openMixFinder(showFilters: true) },
            onInventory: openInventory,
            onProfile: openProfile,
            makeMixDetailModel: makeMixDetailModel
        )
        .tabItem {
            Label(L10n.Tab.home, systemImage: AppSymbol.home)
        }
        .tag(AppTab.home)
    }

    private var mixesTab: some View {
        MixesView(
            model: MixCatalogViewModel(
                content: publicContent,
                library: auth
            ),
            makeMixDetailModel: makeMixDetailModel
        )
        .tabItem {
            Label(L10n.Tab.mixes, systemImage: AppSymbol.grid)
        }
        .tag(AppTab.mixes)
    }

    private var createTab: some View {
        Color.clear
            .tabItem {
                Label(L10n.Tab.create, systemImage: AppSymbol.createFilled)
            }
            .tag(AppTab.create)
    }

    private var articlesTab: some View {
        ArticlesView(
            model: ArticlesViewModel(
                content: publicContent,
                library: auth
            ),
            makeDetailModel: makeArticleDetailModel
        )
        .tabItem {
            Label(L10n.Tab.articles, systemImage: AppSymbol.article)
        }
        .tag(AppTab.articles)
    }

    private var collectionTab: some View {
        CollectionView(
            model: CollectionViewModel(
                service: CollectionService(
                    auth: auth,
                    content: publicContent,
                    inventory: workspace.current?.inventory,
                    personalMixes: workspace.current?.personalMixes
                )
            ),
            makeMixDetail: makeMixDetailModel,
            makeMatches: makeInventoryMatches,
            adminView: makeAdminView
        )
        .id(auth.accountId)
        .tabItem {
            Label(L10n.Tab.collection, systemImage: AppSymbol.bookmarkFilled)
        }
        .tag(AppTab.collection)
    }

    @ViewBuilder
    private var createMixView: some View {
        if let stores = workspace.current {
            CreateMixView(
                model: CreateMixViewModel(
                    service: CreateMixService(
                        content: publicContent,
                        inventory: stores.inventory,
                        personalMixes: stores.personalMixes,
                        client: auth.authorizedClient
                    )
                )
            )
        }
    }

    // MARK: - Private methods

    private func handleTabChange(oldValue: AppTab, newValue: AppTab) {
        guard newValue == .create else {
            previousSelection = newValue
            return
        }

        navigation.tab = oldValue == .create ? previousSelection : oldValue
        if auth.isAuthenticated {
            isCreatePresented = true
        } else {
            auth.gate.request(.create) {
                isCreatePresented = true
            }
        }
    }

    private func openInventory() {
        if auth.isAuthenticated {
            navigation.openInventoryResults()
        } else {
            auth.gate.request(.inventory) {
                navigation.openInventoryResults()
            }
        }
    }

    private func openProfile() {
        if auth.isAuthenticated {
            navigation.tab = .collection
        } else {
            auth.gate.request(.personal) {
                navigation.tab = .collection
            }
        }
    }

    private func makeMixDetailModel(_ mix: MixPreview) -> MixDetailViewModel {
        MixDetailViewModel(
            mix: mix,
            content: publicContent,
            auth: auth
        )
    }

    private func makeArticleDetailModel(_ article: ArticleDTO) -> ArticleDetailViewModel {
        ArticleDetailViewModel(
            article: article,
            content: publicContent,
            library: auth
        )
    }

    private func makeInventoryMatches() -> InventoryMatchesViewModel {
        let service = auth.accountId.flatMap { accountID in
            auth.authorizedClient.map {
                InventoryMatchService(
                    accountID: accountID,
                    client: $0
                )
            }
        }
        return InventoryMatchesViewModel(
            service: service,
            catalog: publicContent.mixes,
            products: publicContent.products
        )
    }

    private func makeAdminView() -> AnyView {
        AnyView(
            Group {
                if auth.isAdmin, let client = auth.authorizedClient {
                    AdminDashboardView(client: client)
                }
            }
        )
    }

    private func authenticate(identityToken: String, authorizationCode: String?) async throws {
        try await auth.authenticate(
            identityToken: identityToken,
            authorizationCode: authorizationCode
        )
    }
}

// MARK: - Preview

#Preview {
    RootView()
}
