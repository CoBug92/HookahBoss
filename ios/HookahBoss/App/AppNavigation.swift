import Foundation

enum AppTab: Hashable {
    case home
    case mixes
    case create
    case articles
    case collection
}

@MainActor
final class AppNavigation: ObservableObject {

    // MARK: - Observable properties

    @Published var tab: AppTab = .home
    @Published var collectionPath: [CollectionDestination] = []
    @Published private(set) var mixFiltersRequest = 0

    // MARK: - Public methods

    func openMixFinder(showFilters: Bool = false) {
        tab = .mixes
        if showFilters {
            mixFiltersRequest += 1
        }
    }

    func openCollection(_ destination: CollectionDestination) {
        tab = .collection
        collectionPath = [destination]
    }

    func openInventoryResults() {
        openCollection(.inventoryResults)
    }
}
