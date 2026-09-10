import Foundation

@MainActor
final class CreateMixViewModel: ObservableObject {
    @Published var title = ""
    @Published var components: [DraftComponent] = []
    @Published private(set) var options = CreateMixOptionSnapshot(catalog: [], personal: [], inventory: [])
    @Published private(set) var isLoading = false
    @Published private(set) var showValidation = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var didSave = false

    private let service: any CreateMixServing
    private var loadTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?
    private var failedAction: FailedAction?

    private enum FailedAction {
        case load(AppLocale)
        case save(PersonalMixRecord)
    }

    init(service: any CreateMixServing) { self.service = service }

    deinit { loadTask?.cancel(); saveTask?.cancel() }

    var distribution: PercentageValidation {
        PercentageDistributor.validate(components.map { Int($0.percentageText) })
    }
    var automaticIndices: Set<Int> {
        if case .valid(_, let automatic) = distribution { return automatic }
        return []
    }
    var validationMessage: String? {
        switch distribution {
        case .noComponents: L10n.Create.Error.component
        case .exceeds100: L10n.Create.Error.over100
        case .percentagesMustTotal100: L10n.Create.Error.total100
        case .insufficientRemainder: L10n.Create.Error.remainder
        case .valid: nil
        }
    }

    func appear(locale: AppLocale = .currentApp) {
        guard loadTask == nil else { return }
        loadTask = Task { await load(locale: locale) }
    }

    func retry(locale: AppLocale = .currentApp) {
        let action = failedAction ?? .load(locale)
        errorMessage = nil
        switch action {
        case .load(let failedLocale):
            loadTask?.cancel()
            loadTask = Task { await load(locale: failedLocale) }
        case .save(let record):
            guard saveTask == nil else { return }
            saveTask = Task { await performSave(record) }
        }
    }

    func add(_ option: ComponentOption) { components.append(DraftComponent(option: option)) }
    func delete(at index: Int) { components.remove(at: index) }
    func moveLeft(from index: Int) { guard index > 0 else { return }; components.swapAt(index, index - 1) }
    func moveRight(from index: Int) { guard index < components.count - 1 else { return }; components.swapAt(index, index + 1) }
    func effectivePercentage(at index: Int) -> Int? {
        if case .valid(let values, _) = distribution { return values[index] }
        return Int(components[index].percentageText)
    }
    func percentageBinding(at index: Int) -> String {
        components[index].percentageText
    }
    func setPercentage(_ value: String, at index: Int) { components[index].percentageText = value }
    func clearError() { errorMessage = nil }

    func save() {
        guard saveTask == nil else { return }
        guard case .valid(let effective, _) = distribution else { showValidation = true; return }
        let records = components.enumerated().map { index, draft in
            PersonalMixComponentRecord(id: UUID(), source: draft.option.source, sourceID: draft.option.sourceID,
                                       brand: draft.option.brand, line: draft.option.line, flavor: draft.option.flavor,
                                       percentage: effective[index], flavorProfiles: draft.option.flavorProfiles)
        }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let record = PersonalMixRecord(id: UUID(), title: trimmed.isEmpty ? nil : trimmed, components: records,
                                       createdAt: Date(), isApproximate: automaticIndices.count == components.count)
        saveTask = Task { await performSave(record) }
    }

    private func load(locale: AppLocale) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false; loadTask = nil }
        do { options = try await service.loadOptions(locale: locale); failedAction = nil }
        catch { failedAction = .load(locale); errorMessage = L10n.Content.Error.network }
    }

    private func performSave(_ record: PersonalMixRecord) async {
        defer { saveTask = nil }
        do { try await service.save(record); failedAction = nil; didSave = true }
        catch { failedAction = .save(record); errorMessage = L10n.Content.Error.network }
    }
}

@MainActor
final class ComponentPickerViewModel: ObservableObject {
    @Published var source: ComponentSource = .catalog
    @Published var search = ""
    private let snapshot: CreateMixOptionSnapshot
    private let excluding: Set<String>

    init(snapshot: CreateMixOptionSnapshot, excluding: Set<String>) {
        self.snapshot = snapshot
        self.excluding = excluding
    }

    var filtered: [ComponentOption] {
        products.map(ComponentOption.init).filter { option in
            !excluding.contains(option.id)
                && (search.isEmpty || (option.flavor + " " + option.brandAndLine).localizedCaseInsensitiveContains(search))
        }
    }

    private var products: [CreateMixProduct] {
        switch source {
        case .catalog: snapshot.catalog
        case .personal: snapshot.personal
        case .inventory: snapshot.inventory
        }
    }
}
