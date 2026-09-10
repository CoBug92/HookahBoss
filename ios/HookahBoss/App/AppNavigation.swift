import Foundation

enum AppTab:Hashable { case home,mixes,create,articles,collection }
enum CollectionDestination:Hashable { case favorites,personal,inventory,inventoryResults }
@MainActor final class AppNavigation:ObservableObject {
    @Published var tab: AppTab
    @Published var collectionPath:[CollectionDestination] = []
    @Published private(set) var mixFiltersRequest = 0
    init() {
        #if DEBUG
        tab = ProcessInfo.processInfo.arguments.contains("--ui-test-mixes") ? .mixes : .home
        #else
        tab = .home
        #endif
    }
    func openMixFinder(showFilters: Bool = false) {
        tab = .mixes
        if showFilters { mixFiltersRequest += 1 }
    }
    func openCollection(_ destination:CollectionDestination){tab = .collection;collectionPath = [destination]}
    func openInventoryResults(){openCollection(.inventoryResults)}
}
