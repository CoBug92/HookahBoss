enum FlavorIntensity: String, CaseIterable, Identifiable, Hashable {
    case any
    case subtle
    case pronounced

    var id: String { rawValue }
}
