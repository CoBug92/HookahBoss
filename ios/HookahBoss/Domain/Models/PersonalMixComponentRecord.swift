import Foundation

struct PersonalMixComponentRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let source: ComponentSource
    let sourceID: String
    let brand: String?
    let line: String?
    let flavor: String
    var percentage: Int?
    var flavorProfiles: [String]? = nil
}
