import Foundation

struct AdminComponentRow: Identifiable, Equatable {
    let id: UUID
    var productId: String
    var productName: String
    var percentage: String

    init(
        id: UUID = UUID(),
        productId: String = "",
        productName: String = "",
        percentage: String = ""
    ) {
        self.id = id
        self.productId = productId
        self.productName = productName
        self.percentage = percentage
    }
}
