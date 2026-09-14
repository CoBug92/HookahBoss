import Foundation

enum MixesPreviewData {
    static let featured = MixPreview(
        id: UUID(),
        title: "Citrus Day",
        flavorTags: ["Lemon", "Mint"],
        flavorProfiles: [.citrus, .fresh],
        sweetness: .subtle,
        acidity: .pronounced,
        freshness: .pronounced,
        ingredients: [
            MixIngredient(
                brand: "Brand",
                line: "Core",
                flavor: "Lemon",
                percentage: 60
            ),
            MixIngredient(
                brand: "Brand",
                flavor: "Mint",
                percentage: 40
            ),
        ],
        rating: 4.7,
        ratingsCount: 42,
        strength: .medium,
        personalRating: 5,
        isFavorite: true,
        palette: .citrus
    )

    static let alternative = MixPreview(
        id: UUID(),
        title: "Berry Night",
        flavorTags: ["Raspberry", "Grapefruit"],
        flavorProfiles: [.berry, .citrus],
        sweetness: .pronounced,
        acidity: .subtle,
        freshness: .any,
        ingredients: [
            MixIngredient(
                brand: "Brand",
                flavor: "Raspberry",
                percentage: 100
            ),
        ],
        rating: 4.5,
        ratingsCount: 18,
        strength: .light,
        personalRating: nil,
        isFavorite: false,
        palette: .berry
    )

    static let catalog = [featured, alternative]
}
