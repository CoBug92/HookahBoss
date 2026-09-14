struct InventoryItem: Identifiable, Codable, Hashable {
    let id: String
    let brand: String
    let line: String?
    let flavor: String
    var level: InventoryLevel
    var flavorProfiles: [String]? = nil

    var brandAndLine: String {
        [brand, line].compactMap { $0 }.joined(separator: " · ")
    }
}
