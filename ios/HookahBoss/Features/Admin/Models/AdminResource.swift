struct AdminResource: Identifiable {
    let path: String
    let title: String
    let fields: [AdminField]

    var id: String {
        path
    }

    static let all: [AdminResource] = [
        .init(
            path: "sources",
            title: L10n.Admin.sources,
            fields: [
                .init(key: "url", title: L10n.Admin.Field.url, kind: .text, required: true),
                .init(key: "title", title: L10n.Admin.Field.title, kind: .text, required: false),
                .init(key: "publisher", title: L10n.Admin.Field.publisher, kind: .text, required: false),
                .init(key: "checkedAt", title: L10n.Admin.Field.checkedAt, kind: .date, required: true),
            ]
        ),
        .init(
            path: "brands",
            title: L10n.Admin.brands,
            fields: content([
                ("slug", L10n.Admin.Field.slug),
                ("name", L10n.Admin.Field.name),
            ])
        ),
        .init(
            path: "lines",
            title: L10n.Admin.lines,
            fields: content([
                ("brandId", L10n.Admin.Field.brandId),
                ("slug", L10n.Admin.Field.slug),
                ("name", L10n.Admin.Field.name),
                ("strength", L10n.Admin.Field.strength),
            ])
        ),
        .init(
            path: "flavor-tags",
            title: L10n.Admin.tags,
            fields: [
                .init(key: "slug", title: L10n.Admin.Field.slug, kind: .text, required: true),
                .init(key: "nameRu", title: L10n.Admin.Field.nameRu, kind: .text, required: true),
                .init(key: "nameEn", title: L10n.Admin.Field.nameEn, kind: .text, required: true),
                .init(key: "profile", title: L10n.Admin.Field.profile, kind: .text, required: true),
            ]
        ),
        .init(
            path: "products",
            title: L10n.Admin.products,
            fields: content([
                ("lineId", L10n.Admin.Field.lineId),
                ("slug", L10n.Admin.Field.slug),
                ("name", L10n.Admin.Field.internalName),
                ("nameRu", L10n.Admin.Field.nameRu),
                ("nameEn", L10n.Admin.Field.nameEn),
                ("sweetness", L10n.Admin.Field.sweetness),
                ("acidity", L10n.Admin.Field.acidity),
                ("freshness", L10n.Admin.Field.freshness),
                ("translationOrigin", L10n.Admin.Field.translationOrigin),
                ("sourceConfidence", L10n.Admin.Field.sourceConfidence),
            ]) + [
                .init(key: "descriptionRu", title: L10n.Admin.Field.descriptionRu, kind: .text, required: false),
                .init(key: "descriptionEn", title: L10n.Admin.Field.descriptionEn, kind: .text, required: false),
                .init(key: "tags", title: L10n.Admin.Field.tags, kind: .json, required: true),
            ]
        ),
        .init(
            path: "official-mixes",
            title: L10n.Admin.mixes,
            fields: content([
                ("slug", L10n.Admin.Field.slug),
                ("titleRu", L10n.Admin.Field.titleRu),
                ("titleEn", L10n.Admin.Field.titleEn),
            ]) + optional([
                ("summaryRu", L10n.Admin.Field.summaryRu),
                ("summaryEn", L10n.Admin.Field.summaryEn),
                ("translationOrigin", L10n.Admin.Field.translationOrigin),
                ("sourceConfidence", L10n.Admin.Field.sourceConfidence),
            ]) + [
                .init(key: "components", title: L10n.Admin.Field.components, kind: .json, required: true),
            ]
        ),
        .init(
            path: "articles",
            title: L10n.Admin.articles,
            fields: localizedContent([
                ("slug", L10n.Admin.Field.slug),
                ("titleRu", L10n.Admin.Field.titleRu),
                ("titleEn", L10n.Admin.Field.titleEn),
                ("summaryRu", L10n.Admin.Field.summaryRu),
                ("summaryEn", L10n.Admin.Field.summaryEn),
                ("bodyRu", L10n.Admin.Field.bodyRu),
                ("bodyEn", L10n.Admin.Field.bodyEn),
            ]) + [
                .init(key: "category", title: L10n.Admin.Field.category, kind: .text, required: true),
                .init(key: "readingMinutes", title: L10n.Admin.Field.readingMinutes, kind: .number, required: true),
                .init(key: "bodyRuStructured", title: L10n.Admin.Field.sectionsRu, kind: .json, required: true),
                .init(key: "bodyEnStructured", title: L10n.Admin.Field.sectionsEn, kind: .json, required: true),
            ]
        ),
        .init(
            path: "substitution-deny-rules",
            title: L10n.Admin.denyRules,
            fields: [
                .init(key: "sourceProductId", title: L10n.Admin.Field.sourceProductId, kind: .text, required: true),
                .init(key: "substituteProductId", title: L10n.Admin.Field.substituteProductId, kind: .text, required: true),
                .init(key: "reason", title: L10n.Admin.Field.reason, kind: .text, required: false),
            ]
        ),
    ]

    static func required(path: String) -> AdminResource {
        guard let resource = all.first(where: { $0.path == path }) else {
            preconditionFailure("Missing admin resource: \(path)")
        }
        return resource
    }

    private static func content(_ base: [(String, String)]) -> [AdminField] {
        base.map {
            .init(key: $0.0, title: $0.1, kind: .text, required: true)
        } + [
            .init(key: "status", title: L10n.Admin.Field.status, kind: .status, required: true),
            .init(key: "sourceId", title: L10n.Admin.Field.sourceId, kind: .text, required: false),
            .init(key: "verifiedAt", title: L10n.Admin.Field.verifiedAt, kind: .date, required: false),
        ]
    }

    private static func localizedContent(_ base: [(String, String)]) -> [AdminField] {
        content(base)
    }

    private static func optional(_ base: [(String, String)]) -> [AdminField] {
        base.map {
            .init(key: $0.0, title: $0.1, kind: .text, required: false)
        }
    }
}
