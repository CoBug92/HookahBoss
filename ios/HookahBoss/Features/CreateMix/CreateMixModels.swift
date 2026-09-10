import Foundation

struct ComponentOption: Identifiable, Hashable {
    let source: ComponentSource
    let sourceID: String
    let brand: String?
    let line: String?
    let flavor: String
    let flavorProfiles: [String]

    var id: String { "\(source.rawValue):\(sourceID)" }
    var brandAndLine: String { [brand, line].compactMap { $0 }.joined(separator: " · ") }

    init(_ product: CreateMixProduct) {
        source = product.source
        sourceID = product.sourceID
        brand = product.brand
        line = product.line
        flavor = product.flavor
        flavorProfiles = product.flavorProfiles
    }
}

struct DraftComponent: Identifiable {
    let id = UUID()
    let option: ComponentOption
    var percentageText = ""
    var optionKey: String { option.id }
}

extension ComponentSource {
    var title: String { switch self {case .catalog:L10n.Create.Source.catalog;case .personal:L10n.Create.Source.personal;case .inventory:L10n.Create.Source.inventory} }
}
