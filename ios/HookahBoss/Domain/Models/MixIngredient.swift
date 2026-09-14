import Foundation

struct MixIngredient: Identifiable, Hashable {
    let id: UUID
    let brand: String
    let line: String?
    let flavor: String
    let percentage: Int

    init(id: UUID = UUID(), brand: String, line: String? = nil, flavor: String, percentage: Int) {
        self.id = id
        self.brand = brand
        self.line = line
        self.flavor = flavor
        self.percentage = percentage
    }

    var brandAndLine: String {
        [brand, line].compactMap { $0 }.joined(separator: " · ")
    }
}
