import UIKit

enum ArtworkResource {
    static func resource(for palette: MixPalette) -> ImageResource {
        switch palette {
        case .berry: .Mixes.berryV2
        case .tropical: .Mixes.fruitV2
        case .citrus: .Mixes.citrusV2
        case .dessert: .Mixes.dessertV2
        case .beverage: .Mixes.beverageV2
        case .herbal: .Mixes.herbalV2
        case .spicy: .Mixes.spicyV2
        case .fresh: .Mixes.freshV2
        case .tropicalCooler: .Mixes.tropicalCooler
        case .forestBerry: .Mixes.forestBerry
        case .peachTea: .Mixes.peachTea
        case .watermelonMint: .Mixes.watermelonMint
        case .cherrySpice: .Mixes.cherrySpice
        case .applePastry: .Mixes.applePastry
        case .grapeSoda: .Mixes.grapeSoda
        case .coconutVanilla: .Mixes.coconutVanilla
        case .cucumberTonic: .Mixes.cucumberTonic
        case .pomegranateCitrus: .Mixes.pomegranateCitrus
        }
    }
}
