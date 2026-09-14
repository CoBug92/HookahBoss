import Foundation

@MainActor
final class InventoryMatchesViewModel: ObservableObject {

    // MARK: - Observable properties

    @Published private(set) var state = InventoryMatchesViewState.loading
    @Published private(set) var ready: [InventoryMixResult] = []
    @Published private(set) var substitutions: [InventoryMixResult] = []
    @Published private(set) var missing: [InventoryMixResult] = []

    // MARK: - Properties

    private let service: (any InventoryMatchServing)?
    private let catalog: [MixPreview]
    private let products: [TobaccoProductDTO]
    private var task: Task<Void, Never>?

    // MARK: - Init/Deinit

    init(
        service: (any InventoryMatchServing)?,
        catalog: [MixPreview],
        products: [TobaccoProductDTO]
    ) {
        self.service = service
        self.catalog = catalog
        self.products = products
    }

    deinit {
        task?.cancel()
    }

    // MARK: - Public methods

    func appear(locale: AppLocale = .currentApp) {
        guard task == nil else { return }
        task = Task { await load(locale: locale) }
    }
    func retry(locale: AppLocale = .currentApp) {
        task?.cancel()
        task = Task { await load(locale: locale) }
    }

    // MARK: - Private methods

    private func load(locale: AppLocale) async {
        state = .loading
        defer { task = nil }
        guard let service else {
            state = .failure
            return
        }

        do {
            classify(try await service.matches(locale: locale))
            state = ready.isEmpty && substitutions.isEmpty && missing.isEmpty
                ? .empty
                : .content
        } catch {
            state = .failure
        }
    }

    private func classify(_ matches: [InventoryMatchDTO]) {
        let productByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        let results = matches.compactMap { match -> InventoryMixResult? in
            guard
                let mix = catalog.first(where: { $0.id == match.mixId }),
                let kind = InventoryMixResult.Kind(rawValue: match.kind)
            else { return nil }

            let note: String?
            if kind == .missing {
                note = match.missingFlavor
            } else if let source = match.sourceProductId.flatMap({ productByID[$0] }),
                let target = match.substituteProductId.flatMap({ productByID[$0] }) {
                note = "\(source.name) → \(target.name)"
            } else {
                note = match.missingFlavor
            }
            return InventoryMixResult(mix: mix, kind: kind, note: note)
        }
        ready = results.filter { $0.kind == .ready }
        substitutions = results.filter { $0.kind == .substitution }
        missing = results.filter { $0.kind == .missing }
    }
}
