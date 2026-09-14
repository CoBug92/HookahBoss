import Foundation

struct AdminTagRow: Identifiable, Equatable {
    let id: UUID
    var tagId: String
    var tagName: String
    var weight: String

    init(
        id: UUID = UUID(),
        tagId: String = "",
        tagName: String = "",
        weight: String = "1"
    ) {
        self.id = id
        self.tagId = tagId
        self.tagName = tagName
        self.weight = weight
    }
}
