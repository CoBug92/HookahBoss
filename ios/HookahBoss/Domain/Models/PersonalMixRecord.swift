import Foundation

struct PersonalMixRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String?
    var components: [PersonalMixComponentRecord]
    let createdAt: Date
    var isApproximate: Bool? = nil
}
