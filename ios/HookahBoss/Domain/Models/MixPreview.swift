import Foundation

struct MixPreview: Identifiable, Hashable {
    let id: UUID
    let title: String
    let flavorTags: [String]
    let flavorProfiles: Set<FlavorProfile>
    let sweetness: FlavorIntensity
    let acidity: FlavorIntensity
    let freshness: FlavorIntensity
    let ingredients: [MixIngredient]
    let rating: Double?
    let ratingsCount: Int
    let strength: MixStrength
    let personalRating: Int?
    let isFavorite: Bool
    let palette: MixPalette

    init(
        id: UUID,
        title: String,
        flavorTags: [String],
        flavorProfiles: Set<FlavorProfile>,
        sweetness: FlavorIntensity,
        acidity: FlavorIntensity,
        freshness: FlavorIntensity,
        ingredients: [MixIngredient],
        rating: Double?,
        ratingsCount: Int,
        strength: MixStrength,
        personalRating: Int?,
        isFavorite: Bool,
        palette: MixPalette
    ) {
        let ingredients = ingredients.mergingDuplicateProducts()
        self.id = id
        self.title = title
        self.flavorTags = ingredients.isEmpty ? flavorTags.uniqueValues() : ingredients.map(\.flavor).uniqueValues()
        self.flavorProfiles = flavorProfiles
        self.sweetness = sweetness
        self.acidity = acidity
        self.freshness = freshness
        self.ingredients = ingredients
        self.rating = rating
        self.ratingsCount = ratingsCount
        self.strength = strength
        self.personalRating = personalRating
        self.isFavorite = isFavorite
        self.palette = palette
    }
}

extension MixPreview {
    func personalized(rating: Int?, favorite: Bool) -> MixPreview {
        .init(
            id: id,
            title: title,
            flavorTags: flavorTags,
            flavorProfiles: flavorProfiles,
            sweetness: sweetness,
            acidity: acidity,
            freshness: freshness,
            ingredients: ingredients,
            rating: self.rating,
            ratingsCount: ratingsCount,
            strength: strength,
            personalRating: rating,
            isFavorite: favorite,
            palette: palette
        )
    }

    func applyingPersonalRatingChange(from previous: Int?, to current: Int?) -> MixPreview {
        guard previous != current else {
            return personalized(rating: current, favorite: isFavorite)
        }

        let previousSum = (rating ?? 0) * Double(ratingsCount)
        let nextCount: Int
        let nextSum: Double

        switch (previous, current) {
        case (nil, .some(let score)):
            nextCount = ratingsCount + 1
            nextSum = previousSum + Double(score)
        case (.some(let old), .some(let score)):
            nextCount = ratingsCount
            nextSum = previousSum - Double(old) + Double(score)
        case (.some(let old), nil):
            nextCount = max(0, ratingsCount - 1)
            nextSum = previousSum - Double(old)
        case (nil, nil):
            nextCount = ratingsCount
            nextSum = previousSum
        }

        let nextRating: Double? = nextCount == 0 ? nil : max(1, min(5, nextSum / Double(nextCount)))
        return .init(
            id: id,
            title: title,
            flavorTags: flavorTags,
            flavorProfiles: flavorProfiles,
            sweetness: sweetness,
            acidity: acidity,
            freshness: freshness,
            ingredients: ingredients,
            rating: nextRating,
            ratingsCount: nextCount,
            strength: strength,
            personalRating: current,
            isFavorite: isFavorite,
            palette: palette
        )
    }
}

private extension Array where Element == MixIngredient {
    func mergingDuplicateProducts() -> [MixIngredient] {
        var result: [MixIngredient] = []
        var indexByProduct: [String: Int] = [:]

        for ingredient in self {
            let key = [ingredient.brand, ingredient.flavor]
                .map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                        .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                }
                .joined(separator: "\u{0}")
            if let index = indexByProduct[key] {
                let existing = result[index]
                result[index] = MixIngredient(
                    id: existing.id,
                    brand: existing.brand,
                    line: existing.line ?? ingredient.line,
                    flavor: existing.flavor,
                    percentage: existing.percentage + ingredient.percentage
                )
            } else {
                indexByProduct[key] = result.count
                result.append(ingredient)
            }
        }
        return result
    }
}

private extension Array where Element == String {
    func uniqueValues() -> [String] {
        var seen: Set<String> = []
        return filter {
            let key = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            return !key.isEmpty && seen.insert(key).inserted
        }
    }
}
