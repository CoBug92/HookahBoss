import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var mixes: [MixPreview] = []
    private let content: any PublicCatalogServing
    private let library: any AuthLibraryServing

    init(content: any PublicCatalogServing, library: any AuthLibraryServing) {
        self.content = content
        self.library = library
    }
    var mixOfDay: MixPreview? { MixRanker.mixOfDay(from: mixes) }
    var recommendations: [MixPreview] { Array(MixRanker.ranked(mixes).prefix(4)) }
    func appear() async { await refresh(force: false) }
    func refresh(force: Bool) async {
        let snapshot = await content.catalog(locale: .currentApp, force: force)
        mixes = snapshot.mixes.map { $0.personalized(rating: library.ratings[$0.id], favorite: library.favoriteMixIDs.contains($0.id)) }
    }
    func syncLibraryState() { mixes = mixes.map { mix in mix.applyingPersonalRatingChange(from:mix.personalRating,to:library.ratings[mix.id]).personalized(rating:library.ratings[mix.id],favorite:library.favoriteMixIDs.contains(mix.id)) } }
}
