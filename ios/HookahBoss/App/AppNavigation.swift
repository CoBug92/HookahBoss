import Foundation

enum AppTab:Hashable { case home,mixes,create,articles,collection }
enum CollectionDestination:Hashable { case favorites,personal,inventory,inventoryResults }
@MainActor final class AppNavigation:ObservableObject {
    @Published var tab:AppTab = .home
    @Published var collectionPath:[CollectionDestination] = []
    func openMixFinder(){tab = .mixes}
    func openCollection(_ destination:CollectionDestination){tab = .collection;collectionPath = [destination]}
    func openInventoryResults(){openCollection(.inventoryResults)}
}
