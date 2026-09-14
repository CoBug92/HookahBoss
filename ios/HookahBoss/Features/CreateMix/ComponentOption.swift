import Foundation

struct ComponentOption {
    let source: ComponentSource
    let sourceID: String
    let brand: String?
    let line: String?
    let flavor: String
    let flavorProfiles: [String]

    var brandAndLine: String {
        [brand, line]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    init(_ product: CreateMixProduct) {
        source = product.source
        sourceID = product.sourceID
        brand = product.brand
        line = product.line
        flavor = product.flavor
        flavorProfiles = product.flavorProfiles
    }
}

// MARK: - Identifiable

extension ComponentOption: Identifiable {
    var id: String {
        "\(source.rawValue):\(sourceID)"
    }
}

// MARK: - Hashable

extension ComponentOption: Hashable {}
