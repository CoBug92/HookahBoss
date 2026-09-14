import Foundation

enum AdminAggregateMapper {
    static func components(_ rows: [AdminComponentRow]) throws -> JSONValue {
        .array(
            try rows.map { row in
                guard !row.productId.isEmpty,
                      let percentage = Int(row.percentage),
                      percentage > 0 else {
                    throw AdminFormValidator.ValidationError.invalid(L10n.Admin.Field.components)
                }
                return .object([
                    "productId": .string(row.productId),
                    "percentage": .number(Double(percentage)),
                ])
            }
        )
    }

    static func tags(_ rows: [AdminTagRow]) throws -> JSONValue {
        .array(
            try rows.map { row in
                guard !row.tagId.isEmpty,
                      let weight = Int(row.weight),
                      (1...5).contains(weight) else {
                    throw AdminFormValidator.ValidationError.invalid(L10n.Admin.Field.tags)
                }
                return .object([
                    "tagId": .string(row.tagId),
                    "weight": .number(Double(weight)),
                ])
            }
        )
    }

    static func articleSections(
        _ rows: [AdminArticleSectionRow]
    ) throws -> (ru: JSONValue, en: JSONValue) {
        guard !rows.isEmpty,
              rows.allSatisfy({ row in
                  !row.headingRu.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      && !row.bodyRu.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      && !row.headingEn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      && !row.bodyEn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              }) else {
            throw AdminFormValidator.ValidationError.invalid(L10n.Admin.sections)
        }
        return (
            .array(rows.map { row in
                .object(["heading": .string(row.headingRu), "body": .string(row.bodyRu)])
            }),
            .array(rows.map { row in
                .object(["heading": .string(row.headingEn), "body": .string(row.bodyEn)])
            })
        )
    }

    static func percentageTotal(_ rows: [AdminComponentRow]) -> Int {
        rows.compactMap { Int($0.percentage) }.reduce(0, +)
    }
}
