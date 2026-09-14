struct CreateMixProduct: Equatable, Sendable {
    let source: ComponentSource
    let sourceID: String
    let brand: String?
    let line: String?
    let flavor: String
    let flavorProfiles: [String]
}
