import SwiftUI

@main
struct HookahBossApp: App {
    @AppStorage("hasConfirmedAdultAge") private var hasConfirmedAdultAge = false
    private let testAgeOverride: Bool?
    private let showsPersonalMixFixture: Bool

    init() {
        #if DEBUG
        let process=ProcessInfo.processInfo
        showsPersonalMixFixture = process.arguments.contains("--ui-test-personal-mix-detail")
        if process.arguments.contains("--ui-test-age-gate") {
            testAgeOverride = false
        } else if process.arguments.contains("--ui-test-bypass-age") {
            testAgeOverride = true
        } else if process.environment["HOOKAHBOSS_UI_TEST"] == "1" {
            testAgeOverride = process.environment["HOOKAHBOSS_UI_TEST_BYPASS_AGE"] == "1"
        } else { testAgeOverride = nil }
        #else
        testAgeOverride = nil
        showsPersonalMixFixture = false
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showsPersonalMixFixture {
                    NavigationStack {
                        PersonalMixDetailView(model: PersonalMixDetailViewModel(mix: .uiTestFixture))
                    }
                } else if testAgeOverride ?? hasConfirmedAdultAge {
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

#if DEBUG
private extension PersonalMixRecord {
    static let uiTestFixture = PersonalMixRecord(
        id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
        title: "Tropical Test Mix",
        components: [
            PersonalMixComponentRecord(
                id: UUID(uuidString: "31000000-0000-0000-0000-000000000001")!,
                source: .catalog,
                sourceID: "product-1",
                brand: "DARKSIDE",
                line: "Core",
                flavor: "Mango",
                percentage: 60,
                flavorProfiles: ["fruit"]
            ),
            PersonalMixComponentRecord(
                id: UUID(uuidString: "31000000-0000-0000-0000-000000000002")!,
                source: .personal,
                sourceID: "private-1",
                brand: "Home",
                line: nil,
                flavor: "Lime",
                percentage: 40,
                flavorProfiles: ["citrus"]
            )
        ],
        createdAt: .distantPast,
        isApproximate: false
    )
}
#endif

private struct RootView: View {
    @StateObject private var auth = AuthRuntime()
    @StateObject private var navigation=AppNavigation()
    @StateObject private var workspace = AccountWorkspace()
    @StateObject private var publicContent = PublicContentStore()
    @State private var previousSelection: AppTab = .home
    @State private var isCreatePresented = false

    var body: some View {
        TabView(selection: $navigation.tab) {
            HomeView(model:HomeViewModel(content:publicContent,library:auth),onFindMix:{navigation.openMixFinder(showFilters: true)},onInventory:{
                if auth.isAuthenticated { navigation.openInventoryResults() } else { auth.gate.request(.inventory){navigation.openInventoryResults()} }
            },onProfile:{
                if auth.isAuthenticated { navigation.tab = .collection }
                else { auth.gate.request(.personal) { navigation.tab = .collection } }
            },makeMixDetailModel:{MixDetailViewModel(mix:$0,content:publicContent,auth:auth)})
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
        .toolbarBackground(AppTheme.card, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
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
            AppTheme.background.ignoresSafeArea()
            Circle().fill(AppTheme.gold.opacity(0.13)).frame(width: 360, height: 360).blur(radius: 3).offset(x: 150, y: -320)
            Circle().fill(Color.orange.opacity(0.09)).frame(width: 300, height: 300).blur(radius: 30).offset(x: -160, y: 250)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 9) {
                    Image(systemName: "smoke.fill").foregroundStyle(AppTheme.gold)
                    Text(L10n.App.brand).font(.caption.weight(.bold)).tracking(1.8)
                }.padding(.top, 20)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 34, style: .continuous).fill(LinearGradient(colors: [Color(red:0.55,green:0.32,blue:0.23), Color(red:0.16,green:0.12,blue:0.10)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Circle().fill(Color.orange.opacity(0.38)).frame(width: 160).blur(radius: 20).offset(x: 110, y: -75)
                    Image(systemName: "18.circle").font(.system(size: 78, weight: .light)).foregroundStyle(.white.opacity(0.94))
                }.frame(height: 245).clipped().clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous)).shadow(color:.black.opacity(0.2),radius:24,y:14)
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.Age.title)
                        .font(.system(size: 38, weight: .bold, design: .serif)).tracking(-1)

                    Text(L10n.Age.message)
                        .font(.body).foregroundStyle(.secondary).lineSpacing(4)
                }.padding(.top, 30)
                Spacer()
                VStack(spacing: 14) {
                    Button(action: confirm) {
                        Text(L10n.Age.confirm)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .foregroundStyle(.white)
                            .background(AppTheme.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .accessibilityIdentifier(AccessibilityID.ageConfirm)

                    Text(L10n.Age.notice)
                        .font(.caption).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 22).padding(.bottom, 14)
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
