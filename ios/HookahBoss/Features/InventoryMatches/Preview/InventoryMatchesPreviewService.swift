import Foundation

@MainActor
final class InventoryMatchesPreviewService: InventoryMatchServing {
    private let values: [InventoryMatchDTO]
    private let delay: Duration?
    private let fails: Bool

    init(
        values: [InventoryMatchDTO] = [],
        delay: Duration? = nil,
        fails: Bool = false
    ) {
        self.values = values
        self.delay = delay
        self.fails = fails
    }

    func matches(locale: AppLocale) async throws -> [InventoryMatchDTO] {
        if let delay {
            try? await Task.sleep(for: delay)
        }
        if fails {
            throw PreviewServiceError.unavailable
        }
        return values
    }
}
