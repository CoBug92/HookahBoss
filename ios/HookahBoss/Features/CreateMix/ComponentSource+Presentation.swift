import Foundation

extension ComponentSource {
    var title: String {
        switch self {
        case .catalog:
            L10n.Create.Source.catalog
        case .personal:
            L10n.Create.Source.personal
        case .inventory:
            L10n.Create.Source.inventory
        }
    }
}
