import Foundation

enum AppTab:Hashable { case home,mixes,create,articles,collection }
enum CollectionDestination:Hashable { case inventoryResults }
@MainActor final class AppNavigation:ObservableObject {
    @Published var tab:AppTab = .home
    @Published var collectionDestination:CollectionDestination?
    func openMixFinder(){tab = .mixes}
    func openInventoryResults(){tab = .collection;collectionDestination = .inventoryResults}
}
