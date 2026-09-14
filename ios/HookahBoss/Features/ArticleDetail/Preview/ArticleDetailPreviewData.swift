import Foundation

enum ArticleDetailPreviewData {
    static let article = ArticleDTO(
        id: UUID(),
        slug: "building-a-mix",
        title: "Как собрать микс с сюжетом",
        summary: "От первого впечатления до послевкусия — без случайного набора ароматов.",
        category: "preparation",
        readingMinutes: 7
    )

    static let related = ArticleDTO(
        id: UUID(),
        slug: "heat-signals",
        title: "Жар без горечи: читаем чашу",
        summary: "Как отличать прогрев от перегрева.",
        category: "bowls_heat",
        readingMinutes: 6
    )

    static let detail = ArticleDetailDTO(
        id: article.id,
        slug: article.slug,
        title: article.title,
        summary: article.summary,
        sections: [
            ArticleSectionDTO(
                heading: "Сначала придумайте направление",
                body: "Опишите будущий микс одной короткой фразой. Такая формулировка помогает отсеять вкусы, которые не работают в выбранном сюжете."
            ),
            ArticleSectionDTO(
                heading: "Распределите роли",
                body: "Основа задаёт характер, поддержка добавляет объём, а акцент появляется позже и не спорит с первым впечатлением."
            ),
            ArticleSectionDTO(
                heading: "Запишите результат",
                body: "Зафиксируйте продукты, доли и одно наблюдение. В следующей попытке меняйте только один параметр."
            ),
        ],
        category: article.category,
        readingMinutes: article.readingMinutes,
        related: [related]
    )
}
