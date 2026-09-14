enum InventoryLevel: String, CaseIterable, Codable, Identifiable {
    case plenty
    case low
    case empty

    var id: String { rawValue }
}
