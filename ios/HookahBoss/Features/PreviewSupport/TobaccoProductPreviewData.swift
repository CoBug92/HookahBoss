import Foundation

enum TobaccoProductPreviewData {
    static let mango = TobaccoProductDTO(
        id: UUID(),
        slug: "preview-mango",
        name: "Mango",
        description: "Ripe tropical mango",
        translationOrigin: "editorial",
        sourceConfidence: "high",
        sweetness: "pronounced",
        acidity: "subtle",
        freshness: "none",
        lineId: UUID(),
        lineName: "Core",
        strength: "medium",
        brandId: UUID(),
        brandName: "DARKSIDE",
        tags: []
    )

    static let lime = TobaccoProductDTO(
        id: UUID(),
        slug: "preview-lime",
        name: "Lime",
        description: "Bright lime peel",
        translationOrigin: "editorial",
        sourceConfidence: "high",
        sweetness: "subtle",
        acidity: "pronounced",
        freshness: "subtle",
        lineId: UUID(),
        lineName: "Element Air",
        strength: "light",
        brandId: UUID(),
        brandName: "Element",
        tags: []
    )

    static let catalog = [mango, lime]
}
