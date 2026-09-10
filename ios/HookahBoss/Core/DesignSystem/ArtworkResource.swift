import UIKit

enum ArtworkResource {
    static func image(for palette: MixPalette) -> UIImage? {
        let file: File = switch palette {
        case .dessert: AssetFiles.mixDessertPng
        case .berry, .citrus: AssetFiles.mixBerryCitrusPng
        case .tropical: AssetFiles.mixTropicalPng
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
