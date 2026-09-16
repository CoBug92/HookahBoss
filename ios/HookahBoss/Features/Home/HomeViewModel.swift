import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Observable properties

    @Published private(set) var mixes: [MixPreview] = []
    @Published private(set) var state = HomeViewState.loading

    // MARK: - Properties

    private let content: any PublicCatalogServing
    private let library: any AuthLibraryServing
    private var libraryChanges: AnyCancellable?

    // MARK: - Computed properties

    var mixOfDay: MixPreview? {
        MixRanker.mixOfDay(from: mixes)
    }

    var recommendations: [MixPreview] {
        MixRanker.dailyRecommendations(from: mixes, excluding: mixOfDay?.id)
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

    func refresh(force: Bool) async {
        if mixes.isEmpty {
            state = .loading
        }

        do {
            let snapshot = try await content.catalog(locale: .currentApp, force: force)
            mixes = snapshot.mixes.map { mix in
                mix.personalized(
                    rating: library.ratings[mix.id],
                    favorite: library.favoriteMixIDs.contains(mix.id)
                )
            }
            if mixes.isEmpty {
                state = snapshot.freshness == .cached ? .failure : .empty
            } else {
                state = snapshot.freshness == .cached ? .cached : .content
            }
        } catch {
            if mixes.isEmpty {
                state = .failure
            }
        }
    }

    func syncLibraryState() {
        mixes = mixes.map { mix in
            mix.applyingPersonalRatingChange(from: mix.personalRating, to: library.ratings[mix.id])
                .personalized(
                    rating: library.ratings[mix.id],
                    favorite: library.favoriteMixIDs.contains(mix.id)
                )
        }
    }
}
