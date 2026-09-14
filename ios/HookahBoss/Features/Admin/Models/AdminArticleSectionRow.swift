import Foundation

struct AdminArticleSectionRow: Identifiable, Equatable {
    let id: UUID
    var headingRu: String
    var bodyRu: String
    var headingEn: String
    var bodyEn: String

    init(
        id: UUID = UUID(),
        headingRu: String = "",
        bodyRu: String = "",
        headingEn: String = "",
        bodyEn: String = ""
    ) {
        self.id = id
        self.headingRu = headingRu
        self.bodyRu = bodyRu
        self.headingEn = headingEn
        self.bodyEn = bodyEn
    }
}
