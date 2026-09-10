import Foundation

@MainActor
final class MixCatalogViewModel: ObservableObject {
    @Published private(set) var catalog: [MixPreview] = []
    @Published private(set) var isLoading = false
    @Published var search = ""
    @Published var filter = MixFilter.empty
    private let content: any PublicCatalogServing
    private let library: any AuthLibraryServing

    init(content: any PublicCatalogServing, library: any AuthLibraryServing) { self.content = content; self.library = library }
    var visibleMixes: [MixPreview] { catalog.filter { search.isEmpty || ($0.title + " " + $0.flavorTags.joined(separator: " ")).localizedCaseInsensitiveContains(search) } }
    var ideal: [MixPreview] { MixRanker.ranked(catalog.filter { filter.matchQuality(for: $0) == .ideal }) }
    var possible: [MixPreview] { MixRanker.ranked(catalog.filter { filter.matchQuality(for: $0) == .possible }) }
    func appear() async { await refresh(force: false) }
    func refresh(force: Bool = true) async {
        isLoading = true; defer { isLoading = false }
        let snapshot = await content.catalog(locale: .currentApp, force: force)
        catalog = snapshot.mixes.map { $0.personalized(rating: library.ratings[$0.id], favorite: library.favoriteMixIDs.contains($0.id)) }
    }
    func syncLibraryState() { catalog = catalog.map { mix in mix.applyingPersonalRatingChange(from:mix.personalRating,to:library.ratings[mix.id]).personalized(rating:library.ratings[mix.id],favorite:library.favoriteMixIDs.contains(mix.id)) } }
    func apply(_ value: MixFilter) { filter = value }
}

@MainActor
final class MixFilterViewModel: ObservableObject {
    @Published var filter: MixFilter
    let catalog: [MixPreview]
    init(catalog: [MixPreview], filter: MixFilter) { self.catalog = catalog; self.filter = filter }
    var resultCount: Int { catalog.filter { filter.matchQuality(for: $0) != nil }.count }
    func toggle(_ profile: FlavorProfile) { if filter.profiles.contains(profile) { filter.profiles.remove(profile) } else { filter.profiles.insert(profile) } }
    func toggleStrength(_ strength: MixStrength) { filter.strength = filter.strength == strength ? nil : strength }
    func reset() { filter = .empty }
}
