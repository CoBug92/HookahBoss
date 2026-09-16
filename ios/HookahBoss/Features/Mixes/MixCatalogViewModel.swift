import Combine
import Foundation

@MainActor
final class MixCatalogViewModel: ObservableObject {

    // MARK: - Observable properties

    @Published private(set) var catalog: [MixPreview] = []
    @Published private(set) var visibleMixes: [MixPreview] = []
    @Published private(set) var state = MixesViewState.loading
    @Published var search = "" { didSet { applySearch() } }
    @Published var filter = MixFilter.empty

    // MARK: - Properties

    private let content: any PublicCatalogServing
    private let library: any AuthLibraryServing
    private var libraryChanges: AnyCancellable?
    private var searchIndex: [UUID: String] = [:]

    // MARK: - Computed properties

    var ideal: [MixPreview] {
        MixRanker.ranked(catalog.filter { filter.matchQuality(for: $0) == .ideal })
    }

    var possible: [MixPreview] {
        MixRanker.ranked(catalog.filter { filter.matchQuality(for: $0) == .possible })
    }

    // MARK: - Init

    init(
        content: any PublicCatalogServing,
        library: any AuthLibraryServing
    ) {
        self.content = content
        self.library = library
        libraryChanges = library.libraryChanges.sink { [weak self] in
            self?.syncLibraryState()
        }
    }

    // MARK: - Public methods

    func appear() async {
        await refresh(force: false)
    }

    func refresh(force: Bool = true) async {
        if catalog.isEmpty {
            state = .loading
        }

        do {
            let snapshot = try await content.catalog(locale: .currentApp, force: force)
            catalog = snapshot.mixes.map { mix in
                mix.personalized(
                    rating: library.ratings[mix.id],
                    favorite: library.favoriteMixIDs.contains(mix.id)
                )
            }
            rebuildSearchIndex()
            applySearch()
            if catalog.isEmpty {
                state = snapshot.freshness == .cached ? .failure : .empty
            } else {
                state = snapshot.freshness == .cached ? .cached : .content
            }
        } catch {
            state = catalog.isEmpty ? .failure : .cached
        }
    }

    func syncLibraryState() {
        catalog = catalog.map { mix in
            mix.applyingPersonalRatingChange(from: mix.personalRating, to: library.ratings[mix.id])
                .personalized(
                    rating: library.ratings[mix.id],
                    favorite: library.favoriteMixIDs.contains(mix.id)
                )
        }
        applySearch()
    }

    func apply(_ value: MixFilter) {
        filter = value
    }

    // MARK: - Private methods

    private func rebuildSearchIndex() {
        searchIndex = Dictionary(
            uniqueKeysWithValues: catalog.map { mix in
                (mix.id, normalized(mix.title + " " + mix.flavorTags.joined(separator: " ")))
            }
        )
    }

    private func applySearch() {
        let query = normalized(search.trimmingCharacters(in: .whitespacesAndNewlines))
        visibleMixes = query.isEmpty ? catalog : catalog.filter { searchIndex[$0.id, default: ""].contains(query) }
    }

    private func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
