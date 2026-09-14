extension ProtectedAction {
    var title: String {
        switch self {
        case .favorite: L10n.Auth.Favorite.title
        case .rating: L10n.Auth.Rating.title
        case .inventory: L10n.Auth.Inventory.title
        case .create: L10n.Auth.Create.title
        case .bookmark: L10n.Auth.Bookmark.title
        case .personal: L10n.Auth.Personal.title
        }
    }

    var body: String {
        switch self {
        case .favorite: L10n.Auth.Favorite.body
        case .rating: L10n.Auth.Rating.body
        case .inventory: L10n.Auth.Inventory.body
        case .create: L10n.Auth.Create.body
        case .bookmark: L10n.Auth.Bookmark.body
        case .personal: L10n.Auth.Personal.body
        }
    }
}
