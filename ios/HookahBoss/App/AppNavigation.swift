import Foundation

enum AppTab:Hashable { case home,mixes,create,articles,collection }
enum CollectionDestination:Hashable { case favorites,personal,inventory,inventoryResults }
@MainActor final class AppNavigation:ObservableObject {
    @Published var tab: AppTab
    @Published var collectionPath:[CollectionDestination] = []
    init() {
        #if DEBUG
        tab = ProcessInfo.processInfo.arguments.contains("--ui-test-mixes") ? .mixes : .home
        #else
        tab = .home
        #endif
    }
    func openMixFinder(){tab = .mixes}
    func openCollection(_ destination:CollectionDestination){tab = .collection;collectionPath = [destination]}
    func openInventoryResults(){openCollection(.inventoryResults)}
}
