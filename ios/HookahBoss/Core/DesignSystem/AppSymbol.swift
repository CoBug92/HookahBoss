import Foundation

enum AppSymbol {

    // MARK: - Navigation

    static let back = "arrow.left"
    static let forward = "arrow.right"
    static let disclosure = "chevron.right"
    static let expand = "chevron.down"
    static let reorder = "chevron.up.chevron.down"

    // MARK: - Library

    static let bookmark = "bookmark"
    static let bookmarkFilled = "bookmark.fill"
    static let bookmarkUnavailable = "bookmark.slash"
    static let favorite = "heart"
    static let favoriteFilled = "heart.fill"
    static let ratingFilled = "star.fill"

    // MARK: - Content

    static let ageRestriction = "18.circle"
    static let adminArticle = "doc.text"
    static let approximate = "approximately"
    static let archive = "archivebox"
    static let article = "book.closed"
    static let basics = "book.closed"
    static let brand = "building.2"
    static let checklist = "checkmark.seal"
    static let collection = "square.stack.3d.up.fill"
    static let create = "plus"
    static let createFilled = "plus.circle.fill"
    static let grid = "square.grid.2x2"
    static let heat = "smoke.fill"
    static let home = "house.fill"
    static let inventory = "shippingbox.fill"
    static let inventoryOutline = "shippingbox"
    static let line = "square.stack.3d.up"
    static let link = "link"
    static let mixing = "square.stack.3d.up.fill"
    static let product = "leaf"
    static let profile = "person.crop.circle"
    static let time = "clock"
    static let tag = "tag"
    static let tools = "wrench.and.screwdriver.fill"

    // MARK: - Actions and status

    static let clear = "xmark.circle.fill"
    static let error = "exclamationmark.circle.fill"
    static let filters = "slider.horizontal.3"
    static let remove = "minus.circle"
    static let retryUnavailable = "wifi.exclamationmark"
    static let search = "magnifyingglass"
    static let sync = "arrow.triangle.swap"
    static let trash = "trash"
    static let tray = "tray"

    // MARK: - Dynamic symbols

    static func articleCategory(_ category: ArticleCategory) -> String {
        switch category {
        case .basics: "book.pages"
        case .preparation: "list.bullet.clipboard"
        case .heat: "flame"
        case .care: "sparkles"
        case .safety: "shield.checkered"
        }
    }
}
