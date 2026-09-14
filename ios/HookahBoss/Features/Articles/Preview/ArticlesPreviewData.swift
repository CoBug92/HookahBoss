import Foundation

enum ArticlesPreviewData {
    static let featured = article(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000001") ?? UUID(),
        slug: "building-a-mix",
        title: "Как собрать микс с сюжетом",
        summary: "От первого впечатления до долгого послевкусия — без случайного набора ароматов.",
        category: "preparation",
        readingMinutes: 7
    )

    static let articles = [
        featured,
        article(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000002") ?? UUID(),
            slug: "heat-signals",
            title: "Жар без горечи: читаем чашу",
            summary: "Как отличать прогрев от перегрева и менять только то, что действительно мешает вкусу.",
            category: "bowls_heat",
            readingMinutes: 6
        ),
        article(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000003") ?? UUID(),
            slug: "hookah-components",
            title: "Анатомия хорошей тяги",
            summary: "Разбираемся, где теряется герметичность и почему мелкие детали меняют ощущения.",
            category: "fundamentals",
            readingMinutes: 6
        ),
        article(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000004") ?? UUID(),
            slug: "routine-cleaning",
            title: "Чистый вкус начинается после сессии",
            summary: "Короткий ритуал ухода, который не даёт старым ароматам испортить следующий микс.",
            category: "care",
            readingMinutes: 5
        ),
        article(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000005") ?? UUID(),
            slug: "first-session-checklist",
            title: "Пять минут до первого угля",
            summary: "Спокойная проверка сборки, места и инвентаря перед началом.",
            category: "fundamentals",
            readingMinutes: 5
        ),
        article(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000006") ?? UUID(),
            slug: "charcoal-co-safety",
            title: "Уголь и угарный газ: без мифов",
            summary: "Что создаёт риск и почему открытое окно не превращает дым в безопасный.",
            category: "safety",
            readingMinutes: 6
        ),
    ]

    static let detail = ArticleDetailDTO(
        id: featured.id,
        slug: featured.slug,
        title: featured.title,
        summary: featured.summary,
        sections: [
            ArticleSectionDTO(
                heading: "Сначала придумайте направление",
                body: "Опишите будущий микс одной короткой фразой: сочный цитрус, холодный лимонад или тёплый десерт. Такая формулировка помогает отсеять вкусы, которые хороши сами по себе, но не работают в выбранном сюжете."
            ),
            ArticleSectionDTO(
                heading: "Распределите роли",
                body: "Основа задаёт узнаваемый характер, поддержка добавляет объём, а акцент появляется позже и не спорит с первым впечатлением. Начните с трёх компонентов и меняйте только один параметр за следующую попытку."
            ),
            ArticleSectionDTO(
                heading: "Запишите результат",
                body: "Зафиксируйте продукты, доли и одно наблюдение о вкусе. Через несколько повторов у вас появится собственная карта сочетаний вместо списка случайных удач."
            ),
        ],
        category: featured.category,
        readingMinutes: featured.readingMinutes,
        related: Array(articles.dropFirst().prefix(2))
    )

    private static func article(
        id: UUID,
        slug: String,
        title: String,
        summary: String,
        category: String,
        readingMinutes: Int
    ) -> ArticleDTO {
        ArticleDTO(
            id: id,
            slug: slug,
            title: title,
            summary: summary,
            category: category,
            readingMinutes: readingMinutes
        )
    }
}
