import Combine
import Foundation

@MainActor
final class MixDetailViewModel: ObservableObject {

    // MARK: - Observable properties

    @Published private(set) var hydratedMix: MixPreview?
    @Published private(set) var personalRating: Int?
    @Published private(set) var isFavorite: Bool
    @Published var errorMessage: String?

    // MARK: - Properties

    private let content: any MixContentServing
    private let auth: any AuthLibraryServing
    private let mix: MixPreview
    private var libraryChanges: AnyCancellable?

    // MARK: - Computed properties

    var displayedMix: MixPreview {
        hydratedMix ?? mix
    }

    // MARK: - Init

    init(
        mix: MixPreview,
        content: any MixContentServing,
        auth: any AuthLibraryServing
    ) {
        self.mix = mix
        self.content = content
        self.auth = auth
        personalRating = mix.personalRating
        isFavorite = mix.isFavorite
        libraryChanges = auth.libraryChanges.sink { [weak self] in
            self?.syncLibraryState()
        }
    }

    // MARK: - Public methods

    func appear(locale: AppLocale = .current) async {
        personalRating = auth.ratings[mix.id]
        isFavorite = auth.favoriteMixIDs.contains(mix.id)
        if let cached = await content.cachedMixDetail(mix.id, locale: locale) {
            hydratedMix = cached
        }
        if let fresh = try? await content.mixDetail(mix.id, locale: locale) {
            hydratedMix = fresh
        }
    }

    func requestFavoriteToggle() {
        auth.authorize(.favorite) { [weak self] in
            Task { await self?.toggleFavorite() }
        }
    }

    func requestRating(_ present: @escaping () -> Void) {
        auth.authorize(.rating, resume: present)
    }

    func submitRating(_ score: Int?) async {
        let previous = personalRating
        personalRating = score
        await auth.setRating(score, mixId: mix.id)
        let committed = auth.ratings[mix.id]
        personalRating = committed
        hydratedMix = displayedMix.applyingPersonalRatingChange(from: previous, to: committed)
        errorMessage = auth.libraryError
    }
    func submitRatingIntent(_ score: Int?) { Task { await submitRating(score) } }

    func dismissError() {
        errorMessage = nil
        auth.libraryError = nil
    }

    private func syncLibraryState() {
        let committedRating = auth.ratings[mix.id]
        hydratedMix = displayedMix.applyingPersonalRatingChange(
            from: personalRating,
            to: committedRating
        )
        personalRating = committedRating
        isFavorite = auth.favoriteMixIDs.contains(mix.id)
    }

    // MARK: - Private methods

    private func toggleFavorite() async {
        let requested = !isFavorite
        isFavorite = requested
        await auth.setFavorite(requested, mixId: mix.id)
        isFavorite = auth.favoriteMixIDs.contains(mix.id)
        errorMessage = auth.libraryError
    }
}
