import Foundation

struct PersonalMixComponentViewData: Identifiable, Equatable {
    let id: UUID
    let flavor: String
    let brandAndLine: String?
    let percentage: Int?
}
