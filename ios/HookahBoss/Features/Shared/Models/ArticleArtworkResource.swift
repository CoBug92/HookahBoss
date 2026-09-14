import UIKit

enum ArticleArtworkResource {
    static func resource(for category: ArticleCategory) -> ImageResource {
        switch category {
        case .basics: .Articles.basics
        case .preparation: .Articles.preparation
        case .heat: .Articles.heat
        case .care: .Articles.care
        case .safety: .Articles.safety
        }
    }

    static func resource(for article: ArticleDTO) -> ImageResource {
        switch article.slug {
        case "hookah-components": .Articles.hookahComponents
        case "first-session-checklist": .Articles.firstSessionChecklist
        case "building-a-mix": .Articles.buildingAMix
        default: resource(for: article.appCategory)
        }
    }
}
