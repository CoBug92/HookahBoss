import Foundation

enum HomePreviewData {
    static let mixOfDay = MixPreview(
        id: UUID(),
        title: "Ягодный закат",
        flavorTags: ["Малина", "Грейпфрут", "Мята"],
        flavorProfiles: [.berry, .citrus, .fresh],
        sweetness: .pronounced,
        acidity: .subtle,
        freshness: .pronounced,
        ingredients: [
            MixIngredient(brand: "Sebero", flavor: "Малина", percentage: 40),
            MixIngredient(brand: "MustHave", flavor: "Грейпфрут", percentage: 35),
            MixIngredient(brand: "BlackBurn", flavor: "Мята", percentage: 25),
        ],
        rating: 4.8,
        ratingsCount: 128,
        strength: .medium,
        personalRating: 5,
        isFavorite: true,
        palette: .berry
    )

    static let recommendations = [
        MixPreview(
            id: UUID(),
            title: "Персиковый чай",
            flavorTags: ["Персик", "Чай"],
            flavorProfiles: [.fruit, .beverage],
            sweetness: .subtle,
            acidity: .subtle,
            freshness: .any,
            ingredients: [
                MixIngredient(brand: "Spectrum", flavor: "Персик", percentage: 55),
                MixIngredient(brand: "Daily Hookah", flavor: "Чай", percentage: 45),
            ],
            rating: 4.6,
            ratingsCount: 84,
            strength: .light,
            personalRating: nil,
            isFavorite: false,
            palette: .peachTea
        ),
        MixPreview(
            id: UUID(),
            title: "Тропический кулер",
            flavorTags: ["Манго", "Ананас", "Лёд"],
            flavorProfiles: [.fruit, .fresh],
            sweetness: .pronounced,
            acidity: .subtle,
            freshness: .pronounced,
            ingredients: [
                MixIngredient(brand: "Darkside", flavor: "Манго", percentage: 40),
                MixIngredient(brand: "Element", flavor: "Ананас", percentage: 35),
                MixIngredient(brand: "Sebero", flavor: "Лёд", percentage: 25),
            ],
            rating: nil,
            ratingsCount: .zero,
            strength: .medium,
            personalRating: nil,
            isFavorite: false,
            palette: .tropicalCooler
        ),
    ]

    static let mixes = [mixOfDay] + recommendations
}
