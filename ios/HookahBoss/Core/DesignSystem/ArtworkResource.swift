import UIKit

enum ArtworkResource {
    static func image(for palette: MixPalette) -> UIImage? {
        let file: File = switch palette {
        case .berry: AssetFiles.mixBerryV2Png
        case .tropical: AssetFiles.mixFruitV2Png
        case .citrus: AssetFiles.mixCitrusV2Png
        case .dessert: AssetFiles.mixDessertV2Png
        case .beverage: AssetFiles.mixBeverageV2Png
        case .herbal: AssetFiles.mixHerbalV2Png
        case .spicy: AssetFiles.mixSpicyV2Png
        case .fresh: AssetFiles.mixFreshV2Png
        }
        return load(file)
    }

    static func image(for category: ArticleCategory) -> UIImage? {
        let file: File = switch category {
        case .basics: AssetFiles.articleBasicsPng
        case .preparation: AssetFiles.articlePreparationPng
        case .heat: AssetFiles.articleHeatPng
        case .care: AssetFiles.articleCarePng
        case .safety: AssetFiles.articleSafetyPng
        }
        return load(file)
    }

    private static func load(_ file: File) -> UIImage? { UIImage(contentsOfFile: file.path) }
}
