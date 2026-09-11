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
        case .tropicalCooler: AssetFiles.mixTropicalCoolerV1Png
        case .forestBerry: AssetFiles.mixForestBerryV1Png
        case .peachTea: AssetFiles.mixPeachTeaV1Png
        case .watermelonMint: AssetFiles.mixWatermelonMintV1Png
        case .cherrySpice: AssetFiles.mixCherrySpiceV1Png
        case .applePastry: AssetFiles.mixApplePastryV1Png
        case .grapeSoda: AssetFiles.mixGrapeSodaV1Png
        case .coconutVanilla: AssetFiles.mixCoconutVanillaV1Png
        case .cucumberTonic: AssetFiles.mixCucumberTonicV1Png
        case .pomegranateCitrus: AssetFiles.mixPomegranateCitrusV1Png
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

    static func image(for article: ArticleDTO) -> UIImage? {
        let resource: String? = switch article.slug {
        case "hookah-components": "article-hookah-components-v1"
        case "first-session-checklist": "article-first-session-checklist-v1"
        case "building-a-mix": "article-building-a-mix-v1"
        default: nil
        }
        guard let resource,
              let url = Bundle.main.url(forResource: resource, withExtension: "png") else {
            return image(for: article.appCategory)
        }
        return UIImage(contentsOfFile: url.path)
    }

    private static func load(_ file: File) -> UIImage? { UIImage(contentsOfFile: file.path) }
}
