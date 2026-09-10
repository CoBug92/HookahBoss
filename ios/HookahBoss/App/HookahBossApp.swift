import SwiftUI

@main
struct HookahBossApp: App {
    @AppStorage("hasConfirmedAdultAge") private var hasConfirmedAdultAge = false
    private let testAgeOverride: Bool?

    init() {
        #if DEBUG
        let process=ProcessInfo.processInfo
        if process.arguments.contains("--ui-test-age-gate") {
            testAgeOverride = false
        } else if process.arguments.contains("--ui-test-bypass-age") {
            testAgeOverride = true
        } else if process.environment["HOOKAHBOSS_UI_TEST"] == "1" {
            testAgeOverride = process.environment["HOOKAHBOSS_UI_TEST_BYPASS_AGE"] == "1"
        } else { testAgeOverride = nil }
        #else
        testAgeOverride = nil
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if testAgeOverride ?? hasConfirmedAdultAge {
                    RootView()
                } else {
                    AgeConfirmationView {
                        hasConfirmedAdultAge = true
                    }
                }
            }
            .preferredColorScheme(nil)
        }
    }
}

private struct RootView: View {
    @StateObject private var auth = AuthRuntime()
    @StateObject private var navigation=AppNavigation()
    @StateObject private var workspace = AccountWorkspace()
    @StateObject private var publicContent = PublicContentStore()
    @State private var previousSelection: AppTab = .home
    @State private var isCreatePresented = false

    var body: some View {
        TabView(selection: $navigation.tab) {
            HomeView(model:HomeViewModel(content:publicContent,library:auth),onFindMix:{navigation.openMixFinder()},onInventory:{
                if auth.isAuthenticated { navigation.openInventoryResults() } else { auth.gate.request(.inventory){navigation.openInventoryResults()} }
            },onProfile:{navigation.tab = .collection},makeMixDetailModel:{MixDetailViewModel(mix:$0,content:publicContent,auth:auth)})
                .tabItem { Label(L10n.Tab.home, systemImage: "house.fill") }
                .tag(AppTab.home)

            MixesView(model:MixCatalogViewModel(content:publicContent,library:auth),makeMixDetailModel:{MixDetailViewModel(mix:$0,content:publicContent,auth:auth)})
                .tabItem { Label(L10n.Tab.mixes, systemImage: "square.grid.2x2") }
                .tag(AppTab.mixes)

            Color.clear
                .tabItem { Label(L10n.Tab.create, systemImage: "plus.circle.fill") }
                .tag(AppTab.create)

            ArticlesView(model:ArticlesViewModel(content:publicContent,library:auth),makeDetailModel:{ArticleDetailViewModel(article:$0,content:publicContent,library:auth)})
                .tabItem { Label(L10n.Tab.articles, systemImage: "book.closed") }
                .tag(AppTab.articles)

            CollectionView(model: CollectionViewModel(service: CollectionService(auth: auth, content: publicContent,
                inventory: workspace.current?.inventory, personalMixes: workspace.current?.personalMixes)),
                makeMixDetail: { MixDetailViewModel(mix:$0,content:publicContent,auth:auth) },
                makeMatches: {
                    let service = auth.accountId.flatMap { accountID in auth.authorizedClient.map { InventoryMatchService(accountID: accountID, client: $0) } }
                    return InventoryMatchViewModel(service: service, catalog: publicContent.mixes, products: publicContent.products)
                },
                adminView: { AnyView(Group { if auth.isAdmin,let client=auth.authorizedClient { AdminDashboardView(client:client) } }) })
                .id(auth.accountId)
                .tabItem { Label(L10n.Tab.collection, systemImage: "bookmark.fill") }
                .tag(AppTab.collection)
        }
        .tint(AppTheme.gold)
        .onChange(of: navigation.tab) { oldValue, newValue in
            if newValue == .create {
                navigation.tab = oldValue == .create ? previousSelection : oldValue
                if auth.isAuthenticated { isCreatePresented = true }
                else { auth.gate.request(.create) { isCreatePresented = true } }
            } else {
                previousSelection = newValue
            }
        }
        .fullScreenCover(isPresented: $isCreatePresented) {
            if let stores=workspace.current {
                CreateMixView(model: CreateMixViewModel(service: CreateMixService(content: publicContent,
                    inventory: stores.inventory, personalMixes: stores.personalMixes, client: auth.authorizedClient)))
            }
        }
        .task { workspace.activate(accountId: auth.accountId) }
        .onChange(of: auth.accountId) { _, accountId in workspace.activate(accountId: accountId) }
        .environmentObject(auth)
        .environmentObject(navigation)
        .modifier(AuthGateSheet(gate:auth.gate,authenticateIdentityToken:{try await auth.authenticate(identityToken:$0,authorizationCode:$1)}))
    }
}

@MainActor
final class AccountWorkspace: ObservableObject {
    struct Stores { let accountId: UUID; let personalMixes: PersonalMixStore; let inventory: InventoryStore }
    @Published private(set) var current: Stores?
    func activate(accountId: UUID?, defaults: UserDefaults = .standard) {
        AccountCache.discardLegacy(defaults: defaults)
        guard let accountId else { current = nil; return }
        guard current?.accountId != accountId else { return }
        current = Stores(accountId: accountId, personalMixes: PersonalMixStore(defaults: defaults, accountId: accountId), inventory: InventoryStore(defaults: defaults, accountId: accountId))
    }
}

private struct AgeConfirmationView: View {
    let confirm: () -> Void

    var body: some View {
        ZStack {
            AppTheme.graphite.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppTheme.gold.opacity(0.16))
                        .frame(width: 104, height: 104)

                    Image(systemName: "18.circle.fill")
                        .font(.system(size: 62, weight: .medium))
                        .foregroundStyle(AppTheme.gold)
                }

                VStack(spacing: 12) {
                    Text(L10n.Age.title)
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(L10n.Age.message)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.68))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 14) {
                    Button(action: confirm) {
                        Text(L10n.Age.confirm)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundStyle(.white)
                            .background(AppTheme.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .accessibilityIdentifier(AccessibilityID.ageConfirm)

                    Text(L10n.Age.notice)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.48))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.age")
    }
}

private struct PlaceholderView: View {
    let title: LocalizedStringKey
    let icon: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: icon)
                .navigationTitle(title)
        }
    }
}
