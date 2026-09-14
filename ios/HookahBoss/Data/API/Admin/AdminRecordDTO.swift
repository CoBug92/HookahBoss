import Foundation

struct AdminRecordDTO: Codable, Identifiable, Equatable {
    let values: [String: JSONValue]

    var id: String {
        values["id"]?.display ?? UUID().uuidString
    }

    var title: String {
        for key in ["name", "title", "titleRu", "slug", "url", "reason"] {
            if let value = values[key]?.display, !value.isEmpty {
                return value
            }
        }
        return id
    }

    init(from decoder: Decoder) throws {
        values = try [String: JSONValue](from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        try values.encode(to: encoder)
    }
}
