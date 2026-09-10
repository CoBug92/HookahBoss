// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  public enum Accessibility {
    /// Not rated
    public static let notRated = L10n.tr("Localizable", "accessibility.notRated", fallback: "Not rated")
    /// Not selected
    public static let notSelected = L10n.tr("Localizable", "accessibility.notSelected", fallback: "Not selected")
    /// Selected
    public static let selected = L10n.tr("Localizable", "accessibility.selected", fallback: "Selected")
  }
  public enum Account {
    /// Delete Account
    public static let delete = L10n.tr("Localizable", "account.delete", fallback: "Delete Account")
    /// Sign out
    public static let logout = L10n.tr("Localizable", "account.logout", fallback: "Sign out")
    /// Account
    public static let settings = L10n.tr("Localizable", "account.settings", fallback: "Account")
    public enum Delete {
      /// Delete account?
      public static let confirm = L10n.tr("Localizable", "account.delete.confirm", fallback: "Delete account?")
      /// Server data and this account’s local data will be deleted. Apple ID authorization is managed separately in Apple settings.
      public static let message = L10n.tr("Localizable", "account.delete.message", fallback: "Server data and this account’s local data will be deleted. Apple ID authorization is managed separately in Apple settings.")
      public enum ProviderUnavailable {
        /// Your app data was deleted, but no Apple provider credential was available to revoke. You can remove the authorization in Apple ID settings.
        public static let message = L10n.tr("Localizable", "account.delete.providerUnavailable.message", fallback: "Your app data was deleted, but no Apple provider credential was available to revoke. You can remove the authorization in Apple ID settings.")
        /// Account deleted
        public static let title = L10n.tr("Localizable", "account.delete.providerUnavailable.title", fallback: "Account deleted")
      }
    }
  }
  public enum Admin {
    /// Add component
    public static let addComponent = L10n.tr("Localizable", "admin.addComponent", fallback: "Add component")
    /// Add section
    public static let addSection = L10n.tr("Localizable", "admin.addSection", fallback: "Add section")
    /// Add tag
    public static let addTag = L10n.tr("Localizable", "admin.addTag", fallback: "Add tag")
    /// Archive
    public static let archive = L10n.tr("Localizable", "admin.archive", fallback: "Archive")
    /// Articles
    public static let articles = L10n.tr("Localizable", "admin.articles", fallback: "Articles")
    /// Brands
    public static let brands = L10n.tr("Localizable", "admin.brands", fallback: "Brands")
    /// Choose
    public static let choose = L10n.tr("Localizable", "admin.choose", fallback: "Choose")
    /// Components
    public static let components = L10n.tr("Localizable", "admin.components", fallback: "Components")
    /// Create
    public static let create = L10n.tr("Localizable", "admin.create", fallback: "Create")
    /// Substitution deny rules
    public static let denyRules = L10n.tr("Localizable", "admin.denyRules", fallback: "Substitution deny rules")
    /// Edit
    public static let edit = L10n.tr("Localizable", "admin.edit", fallback: "Edit")
    /// Nothing here yet
    public static let empty = L10n.tr("Localizable", "admin.empty", fallback: "Nothing here yet")
    /// Lines
    public static let lines = L10n.tr("Localizable", "admin.lines", fallback: "Lines")
    /// Official mixes
    public static let mixes = L10n.tr("Localizable", "admin.mixes", fallback: "Official mixes")
    /// Products
    public static let products = L10n.tr("Localizable", "admin.products", fallback: "Products")
    /// Publish
    public static let publish = L10n.tr("Localizable", "admin.publish", fallback: "Publish")
    /// RU / EN sections
    public static let sections = L10n.tr("Localizable", "admin.sections", fallback: "RU / EN sections")
    /// Manage catalogue and editorial content
    public static let serviceHint = L10n.tr("Localizable", "admin.serviceHint", fallback: "Manage catalogue and editorial content")
    /// Administration
    public static let serviceSection = L10n.tr("Localizable", "admin.serviceSection", fallback: "Administration")
    /// Sources
    public static let sources = L10n.tr("Localizable", "admin.sources", fallback: "Sources")
    /// Flavor tags
    public static let tags = L10n.tr("Localizable", "admin.tags", fallback: "Flavor tags")
    /// Administration
    public static let title = L10n.tr("Localizable", "admin.title", fallback: "Administration")
    public enum Dashboard {
      /// %d items
      public static func items(_ p1: Int) -> String {
        return L10n.tr("Localizable", "admin.dashboard.items", p1, fallback: "%d items")
      }
      /// Loading…
      public static let loading = L10n.tr("Localizable", "admin.dashboard.loading", fallback: "Loading…")
      /// Status unavailable
      public static let unavailable = L10n.tr("Localizable", "admin.dashboard.unavailable", fallback: "Status unavailable")
    }
    public enum Field {
      /// Acidity
      public static let acidity = L10n.tr("Localizable", "admin.field.acidity", fallback: "Acidity")
      /// Plain body · EN
      public static let bodyEn = L10n.tr("Localizable", "admin.field.bodyEn", fallback: "Plain body · EN")
      /// Plain body · RU
      public static let bodyRu = L10n.tr("Localizable", "admin.field.bodyRu", fallback: "Plain body · RU")
      /// Brand ID
      public static let brandId = L10n.tr("Localizable", "admin.field.brandId", fallback: "Brand ID")
      /// Category
      public static let category = L10n.tr("Localizable", "admin.field.category", fallback: "Category")
      /// Checked at
      public static let checkedAt = L10n.tr("Localizable", "admin.field.checkedAt", fallback: "Checked at")
      /// Components
      public static let components = L10n.tr("Localizable", "admin.field.components", fallback: "Components")
      /// Description · EN
      public static let descriptionEn = L10n.tr("Localizable", "admin.field.descriptionEn", fallback: "Description · EN")
      /// Description · RU
      public static let descriptionRu = L10n.tr("Localizable", "admin.field.descriptionRu", fallback: "Description · RU")
      /// Freshness
      public static let freshness = L10n.tr("Localizable", "admin.field.freshness", fallback: "Freshness")
      /// Internal name
      public static let internalName = L10n.tr("Localizable", "admin.field.internalName", fallback: "Internal name")
      /// Line ID
      public static let lineId = L10n.tr("Localizable", "admin.field.lineId", fallback: "Line ID")
      /// Name
      public static let name = L10n.tr("Localizable", "admin.field.name", fallback: "Name")
      /// Name · EN
      public static let nameEn = L10n.tr("Localizable", "admin.field.nameEn", fallback: "Name · EN")
      /// Name · RU
      public static let nameRu = L10n.tr("Localizable", "admin.field.nameRu", fallback: "Name · RU")
      /// Profile
      public static let profile = L10n.tr("Localizable", "admin.field.profile", fallback: "Profile")
      /// Publisher
      public static let publisher = L10n.tr("Localizable", "admin.field.publisher", fallback: "Publisher")
      /// Reading minutes
      public static let readingMinutes = L10n.tr("Localizable", "admin.field.readingMinutes", fallback: "Reading minutes")
      /// Reason
      public static let reason = L10n.tr("Localizable", "admin.field.reason", fallback: "Reason")
      /// Sections · EN
      public static let sectionsEn = L10n.tr("Localizable", "admin.field.sectionsEn", fallback: "Sections · EN")
      /// Sections · RU
      public static let sectionsRu = L10n.tr("Localizable", "admin.field.sectionsRu", fallback: "Sections · RU")
      /// Slug
      public static let slug = L10n.tr("Localizable", "admin.field.slug", fallback: "Slug")
      /// Source confidence
      public static let sourceConfidence = L10n.tr("Localizable", "admin.field.sourceConfidence", fallback: "Source confidence")
      /// Source ID
      public static let sourceId = L10n.tr("Localizable", "admin.field.sourceId", fallback: "Source ID")
      /// Source product ID
      public static let sourceProductId = L10n.tr("Localizable", "admin.field.sourceProductId", fallback: "Source product ID")
      /// Status
      public static let status = L10n.tr("Localizable", "admin.field.status", fallback: "Status")
      /// Strength
      public static let strength = L10n.tr("Localizable", "admin.field.strength", fallback: "Strength")
      /// Substitute product ID
      public static let substituteProductId = L10n.tr("Localizable", "admin.field.substituteProductId", fallback: "Substitute product ID")
      /// Summary · EN
      public static let summaryEn = L10n.tr("Localizable", "admin.field.summaryEn", fallback: "Summary · EN")
      /// Summary · RU
      public static let summaryRu = L10n.tr("Localizable", "admin.field.summaryRu", fallback: "Summary · RU")
      /// Sweetness
      public static let sweetness = L10n.tr("Localizable", "admin.field.sweetness", fallback: "Sweetness")
      /// Tags
      public static let tags = L10n.tr("Localizable", "admin.field.tags", fallback: "Tags")
      /// Title
      public static let title = L10n.tr("Localizable", "admin.field.title", fallback: "Title")
      /// Title · EN
      public static let titleEn = L10n.tr("Localizable", "admin.field.titleEn", fallback: "Title · EN")
      /// Title · RU
      public static let titleRu = L10n.tr("Localizable", "admin.field.titleRu", fallback: "Title · RU")
      /// Translation origin
      public static let translationOrigin = L10n.tr("Localizable", "admin.field.translationOrigin", fallback: "Translation origin")
      /// URL
      public static let url = L10n.tr("Localizable", "admin.field.url", fallback: "URL")
      /// Verified at
      public static let verifiedAt = L10n.tr("Localizable", "admin.field.verifiedAt", fallback: "Verified at")
    }
    public enum Section {
      /// Body · EN
      public static let bodyEn = L10n.tr("Localizable", "admin.section.bodyEn", fallback: "Body · EN")
      /// Body · RU
      public static let bodyRu = L10n.tr("Localizable", "admin.section.bodyRu", fallback: "Body · RU")
      /// Heading · EN
      public static let headingEn = L10n.tr("Localizable", "admin.section.headingEn", fallback: "Heading · EN")
      /// Heading · RU
      public static let headingRu = L10n.tr("Localizable", "admin.section.headingRu", fallback: "Heading · RU")
    }
    public enum Status {
      /// Archived
      public static let archived = L10n.tr("Localizable", "admin.status.archived", fallback: "Archived")
      /// Draft
      public static let draft = L10n.tr("Localizable", "admin.status.draft", fallback: "Draft")
      /// Published
      public static let published = L10n.tr("Localizable", "admin.status.published", fallback: "Published")
    }
    public enum Validation {
      /// Invalid: %@
      public static func invalid(_ p1: Any) -> String {
        return L10n.tr("Localizable", "admin.validation.invalid", String(describing: p1), fallback: "Invalid: %@")
      }
      /// Mix percentages must total 100
      public static let percentages = L10n.tr("Localizable", "admin.validation.percentages", fallback: "Mix percentages must total 100")
      /// Published or archived content requires a source and verification date
      public static let provenance = L10n.tr("Localizable", "admin.validation.provenance", fallback: "Published or archived content requires a source and verification date")
      /// Required: %@
      public static func `required`(_ p1: Any) -> String {
        return L10n.tr("Localizable", "admin.validation.required", String(describing: p1), fallback: "Required: %@")
      }
    }
  }
  public enum Age {
    /// I am 18 or older
    public static let confirm = L10n.tr("Localizable", "age.confirm", fallback: "I am 18 or older")
    /// This app contains reference information about hookah tobacco and is intended for adults aged 18 and over.
    public static let message = L10n.tr("Localizable", "age.message", fallback: "This app contains reference information about hookah tobacco and is intended for adults aged 18 and over.")
    /// The app does not sell tobacco products and is not intended to encourage their use.
    public static let notice = L10n.tr("Localizable", "age.notice", fallback: "The app does not sell tobacco products and is not intended to encourage their use.")
    /// For adults only
    public static let title = L10n.tr("Localizable", "age.title", fallback: "For adults only")
  }
  public enum Article {
    public enum Balance {
      /// Choose one clear primary flavor. A second component should support it or provide an intentional contrast. Strong spices, herbs, and cooling work best as accents.
      ///
      /// Use simple ratios for the first attempt and change only one component at a time, making the result easier to understand.
      public static let body = L10n.tr("Localizable", "article.balance.body", fallback: "Choose one clear primary flavor. A second component should support it or provide an intentional contrast. Strong spices, herbs, and cooling work best as accents.\n\nUse simple ratios for the first attempt and change only one component at a time, making the result easier to understand.")
      /// Base and accent
      public static let section1 = L10n.tr("Localizable", "article.balance.section1", fallback: "Base and accent")
      /// Repeatable results
      public static let section2 = L10n.tr("Localizable", "article.balance.section2", fallback: "Repeatable results")
      /// A simple way to combine a base, an accent, and freshness.
      public static let summary = L10n.tr("Localizable", "article.balance.summary", fallback: "A simple way to combine a base, an accent, and freshness.")
      /// Building a balanced flavor
      public static let title = L10n.tr("Localizable", "article.balance.title", fallback: "Building a balanced flavor")
    }
    public enum Care {
      /// Once cool, disassemble the hookah, remove the remaining mixture, and rinse the parts with warm water. Pay particular attention to the stem, base, and seals.
      ///
      /// Dry every part before assembly. Check seals regularly and avoid abrasive cleaners on delicate finishes.
      public static let body = L10n.tr("Localizable", "article.care.body", fallback: "Once cool, disassemble the hookah, remove the remaining mixture, and rinse the parts with warm water. Pay particular attention to the stem, base, and seals.\n\nDry every part before assembly. Check seals regularly and avoid abrasive cleaners on delicate finishes.")
      /// After cooling
      public static let section1 = L10n.tr("Localizable", "article.care.section1", fallback: "After cooling")
      /// Drying and storage
      public static let section2 = L10n.tr("Localizable", "article.care.section2", fallback: "Drying and storage")
      /// A short cleaning routine that avoids lingering odors.
      public static let summary = L10n.tr("Localizable", "article.care.summary", fallback: "A short cleaning routine that avoids lingering odors.")
      /// Care after a session
      public static let title = L10n.tr("Localizable", "article.care.title", fallback: "Care after a session")
    }
    public enum FirstBowl {
      /// Start with a clean hookah and a familiar bowl. Distribute the mixture evenly without blocking airflow. Leave a small gap below the heat-management device or foil.
      ///
      /// Warm the bowl gradually and judge the flavor rather than the amount of smoke. If it turns harsh, reduce the heat first and let the bowl cool briefly.
      public static let body = L10n.tr("Localizable", "article.firstBowl.body", fallback: "Start with a clean hookah and a familiar bowl. Distribute the mixture evenly without blocking airflow. Leave a small gap below the heat-management device or foil.\n\nWarm the bowl gradually and judge the flavor rather than the amount of smoke. If it turns harsh, reduce the heat first and let the bowl cool briefly.")
      /// Preparation
      public static let section1 = L10n.tr("Localizable", "article.firstBowl.section1", fallback: "Preparation")
      /// Managing heat
      public static let section2 = L10n.tr("Localizable", "article.firstBowl.section2", fallback: "Managing heat")
      /// A short guide to the essentials of preparation.
      public static let summary = L10n.tr("Localizable", "article.firstBowl.summary", fallback: "A short guide to the essentials of preparation.")
      /// A straightforward first bowl
      public static let title = L10n.tr("Localizable", "article.firstBowl.title", fallback: "A straightforward first bowl")
    }
    public enum Heat {
      /// Different bowls warm at different rates, so there is no universal number of coals. Begin with moderate heat and watch the aroma and bowl temperature.
      ///
      /// A dry, sharp taste and rapidly fading aroma are signs to remove some heat. Give the bowl time to recover after adjusting it.
      public static let body = L10n.tr("Localizable", "article.heat.body", fallback: "Different bowls warm at different rates, so there is no universal number of coals. Begin with moderate heat and watch the aroma and bowl temperature.\n\nA dry, sharp taste and rapidly fading aroma are signs to remove some heat. Give the bowl time to recover after adjusting it.")
      /// Start moderately
      public static let section1 = L10n.tr("Localizable", "article.heat.section1", fallback: "Start moderately")
      /// Overheating signals
      public static let section2 = L10n.tr("Localizable", "article.heat.section2", fallback: "Overheating signals")
      /// How to notice overheating before bitterness appears.
      public static let summary = L10n.tr("Localizable", "article.heat.summary", fallback: "How to notice overheating before bitterness appears.")
      /// Bowls and heat management
      public static let title = L10n.tr("Localizable", "article.heat.title", fallback: "Bowls and heat management")
    }
    public enum Safety {
      /// Use a hookah only in a well-ventilated space and place it on a stable surface away from children, pets, and flammable materials.
      ///
      /// Move charcoal with tongs over a nonflammable surface. Never leave heat or charcoal unattended, and make sure it is fully extinguished afterward.
      public static let body = L10n.tr("Localizable", "article.safety.body", fallback: "Use a hookah only in a well-ventilated space and place it on a stable surface away from children, pets, and flammable materials.\n\nMove charcoal with tongs over a nonflammable surface. Never leave heat or charcoal unattended, and make sure it is fully extinguished afterward.")
      /// Air and stability
      public static let section1 = L10n.tr("Localizable", "article.safety.section1", fallback: "Air and stability")
      /// Handling charcoal
      public static let section2 = L10n.tr("Localizable", "article.safety.section2", fallback: "Handling charcoal")
      /// Ventilation, stability, and handling charcoal.
      public static let summary = L10n.tr("Localizable", "article.safety.summary", fallback: "Ventilation, stability, and handling charcoal.")
      /// A safer session at home
      public static let title = L10n.tr("Localizable", "article.safety.title", fallback: "A safer session at home")
    }
  }
  public enum Articles {
    /// Bookmarks
    public static let bookmarks = L10n.tr("Localizable", "articles.bookmarks", fallback: "Bookmarks")
    /// %lld article
    public static func countLld(_ p1: Int) -> String {
      return L10n.tr("Localizable", "articles.count %lld", p1, fallback: "%lld article")
    }
    /// No articles in this category yet
    public static let empty = L10n.tr("Localizable", "articles.empty", fallback: "No articles in this category yet")
    /// %lld min read
    public static func minutesLld(_ p1: Int) -> String {
      return L10n.tr("Localizable", "articles.minutes %lld", p1, fallback: "%lld min read")
    }
    /// Recommended
    public static let recommended = L10n.tr("Localizable", "articles.recommended", fallback: "Recommended")
    /// Related articles
    public static let related = L10n.tr("Localizable", "articles.related", fallback: "Related articles")
    /// Practical guides from the editorial team
    public static let subtitle = L10n.tr("Localizable", "articles.subtitle", fallback: "Practical guides from the editorial team")
    public enum Bookmark {
      /// Add bookmark
      public static let add = L10n.tr("Localizable", "articles.bookmark.add", fallback: "Add bookmark")
      /// Remove bookmark
      public static let remove = L10n.tr("Localizable", "articles.bookmark.remove", fallback: "Remove bookmark")
    }
    public enum Bookmarks {
      /// No bookmarked articles yet
      public static let empty = L10n.tr("Localizable", "articles.bookmarks.empty", fallback: "No bookmarked articles yet")
    }
    public enum Category {
      /// Basics
      public static let basics = L10n.tr("Localizable", "articles.category.basics", fallback: "Basics")
      /// Care
      public static let care = L10n.tr("Localizable", "articles.category.care", fallback: "Care")
      /// Bowls & heat
      public static let heat = L10n.tr("Localizable", "articles.category.heat", fallback: "Bowls & heat")
      /// Preparation
      public static let preparation = L10n.tr("Localizable", "articles.category.preparation", fallback: "Preparation")
      /// Safety
      public static let safety = L10n.tr("Localizable", "articles.category.safety", fallback: "Safety")
    }
  }
  public enum Auth {
    /// Continue with Apple
    public static let apple = L10n.tr("Localizable", "auth.apple", fallback: "Continue with Apple")
    /// Cancel
    public static let cancel = L10n.tr("Localizable", "auth.cancel", fallback: "Cancel")
    /// Sign-in failed. Please try again.
    public static let error = L10n.tr("Localizable", "auth.error", fallback: "Sign-in failed. Please try again.")
    /// Signing in
    public static let loading = L10n.tr("Localizable", "auth.loading", fallback: "Signing in")
    /// Tap Continue with Apple to retry.
    public static let retryHint = L10n.tr("Localizable", "auth.retryHint", fallback: "Tap Continue with Apple to retry.")
    public enum Bookmark {
      /// Sign in with Apple to keep bookmarks available across your devices.
      public static let body = L10n.tr("Localizable", "auth.bookmark.body", fallback: "Sign in with Apple to keep bookmarks available across your devices.")
      /// Save this article?
      public static let title = L10n.tr("Localizable", "auth.bookmark.title", fallback: "Save this article?")
    }
    public enum Create {
      /// Sign in with Apple to save personal mixes.
      public static let body = L10n.tr("Localizable", "auth.create.body", fallback: "Sign in with Apple to save personal mixes.")
      /// Create a personal mix
      public static let title = L10n.tr("Localizable", "auth.create.title", fallback: "Create a personal mix")
    }
    public enum Favorite {
      /// Sign in with Apple to link favorites to your account.
      public static let body = L10n.tr("Localizable", "auth.favorite.body", fallback: "Sign in with Apple to link favorites to your account.")
      /// Save to favorites
      public static let title = L10n.tr("Localizable", "auth.favorite.title", fallback: "Save to favorites")
    }
    public enum Inventory {
      /// Sign in with Apple to keep your products and stock levels.
      public static let body = L10n.tr("Localizable", "auth.inventory.body", fallback: "Sign in with Apple to keep your products and stock levels.")
      /// Open inventory
      public static let title = L10n.tr("Localizable", "auth.inventory.title", fallback: "Open inventory")
    }
    public enum Personal {
      /// Sign in with Apple to keep and sync your personal mixes.
      public static let body = L10n.tr("Localizable", "auth.personal.body", fallback: "Sign in with Apple to keep and sync your personal mixes.")
      /// Your personal mixes
      public static let title = L10n.tr("Localizable", "auth.personal.title", fallback: "Your personal mixes")
    }
    public enum Rating {
      /// Sign in with Apple to rate a mix.
      public static let body = L10n.tr("Localizable", "auth.rating.body", fallback: "Sign in with Apple to rate a mix.")
      /// Rate this mix
      public static let title = L10n.tr("Localizable", "auth.rating.title", fallback: "Rate this mix")
    }
  }
  public enum Bookmark {
    /// Add bookmark
    public static let add = L10n.tr("Localizable", "bookmark.add", fallback: "Add bookmark")
    /// Remove bookmark
    public static let remove = L10n.tr("Localizable", "bookmark.remove", fallback: "Remove bookmark")
  }
  public enum Collection {
    /// %lld components
    public static func componentsLld(_ p1: Int) -> String {
      return L10n.tr("Localizable", "collection.components %lld", p1, fallback: "%lld components")
    }
    /// Personal mixes
    public static let personalMixes = L10n.tr("Localizable", "collection.personalMixes", fallback: "Personal mixes")
    /// Untitled mix
    public static let untitledMix = L10n.tr("Localizable", "collection.untitledMix", fallback: "Untitled mix")
  }
  public enum Common {
    /// See all
    public static let all = L10n.tr("Localizable", "common.all", fallback: "See all")
    /// Back
    public static let back = L10n.tr("Localizable", "common.back", fallback: "Back")
    /// Cancel
    public static let cancel = L10n.tr("Localizable", "common.cancel", fallback: "Cancel")
    /// Close
    public static let close = L10n.tr("Localizable", "common.close", fallback: "Close")
    /// Delete
    public static let delete = L10n.tr("Localizable", "common.delete", fallback: "Delete")
    /// Retry
    public static let retry = L10n.tr("Localizable", "common.retry", fallback: "Retry")
    /// Save
    public static let save = L10n.tr("Localizable", "common.save", fallback: "Save")
  }
  public enum Content {
    public enum Empty {
      /// No articles have been published yet
      public static let articles = L10n.tr("Localizable", "content.empty.articles", fallback: "No articles have been published yet")
      /// No mixes have been published yet
      public static let mixes = L10n.tr("Localizable", "content.empty.mixes", fallback: "No mixes have been published yet")
    }
    public enum Error {
      /// The API address is not configured.
      public static let configuration = L10n.tr("Localizable", "content.error.configuration", fallback: "The API address is not configured.")
      /// No connection or saved data. Pull down to retry.
      public static let network = L10n.tr("Localizable", "content.error.network", fallback: "No connection or saved data. Pull down to retry.")
      /// Unable to load
      public static let title = L10n.tr("Localizable", "content.error.title", fallback: "Unable to load")
    }
  }
  public enum Create {
    /// Add
    public static let add = L10n.tr("Localizable", "create.add", fallback: "Add")
    /// auto %lld%%
    public static func autoLld(_ p1: Int) -> String {
      return L10n.tr("Localizable", "create.auto %lld", p1, fallback: "auto %lld%%")
    }
    /// Choose a component
    public static let choose = L10n.tr("Localizable", "create.choose", fallback: "Choose a component")
    /// Composition
    public static let composition = L10n.tr("Localizable", "create.composition", fallback: "Composition")
    /// Add the first component
    public static let firstComponent = L10n.tr("Localizable", "create.firstComponent", fallback: "Add the first component")
    /// Move left
    public static let moveLeft = L10n.tr("Localizable", "create.moveLeft", fallback: "Move left")
    /// Move right
    public static let moveRight = L10n.tr("Localizable", "create.moveRight", fallback: "Move right")
    /// Flavor, brand, or line
    public static let search = L10n.tr("Localizable", "create.search", fallback: "Flavor, brand, or line")
    /// Source
    public static let source = L10n.tr("Localizable", "create.source", fallback: "Source")
    /// New mix
    public static let title = L10n.tr("Localizable", "create.title", fallback: "New mix")
    public enum Error {
      /// Add at least one component.
      public static let component = L10n.tr("Localizable", "create.error.component", fallback: "Add at least one component.")
      /// The percentage total cannot exceed 100.
      public static let over100 = L10n.tr("Localizable", "create.error.over100", fallback: "The percentage total cannot exceed 100.")
      /// The remaining percentage is too small for automatic distribution.
      public static let remainder = L10n.tr("Localizable", "create.error.remainder", fallback: "The remaining percentage is too small for automatic distribution.")
      /// When every percentage is entered, the total must equal 100.
      public static let total100 = L10n.tr("Localizable", "create.error.total100", fallback: "When every percentage is entered, the total must equal 100.")
    }
    public enum FirstComponent {
      /// Choose tobacco from the catalog, personal items, or inventory
      public static let hint = L10n.tr("Localizable", "create.firstComponent.hint", fallback: "Choose tobacco from the catalog, personal items, or inventory")
    }
    public enum Sample {
      /// Homemade peach
      public static let personalPeach = L10n.tr("Localizable", "create.sample.personalPeach", fallback: "Homemade peach")
    }
    public enum Source {
      /// Catalog
      public static let catalog = L10n.tr("Localizable", "create.source.catalog", fallback: "Catalog")
      /// Inventory
      public static let inventory = L10n.tr("Localizable", "create.source.inventory", fallback: "Inventory")
      /// Personal
      public static let personal = L10n.tr("Localizable", "create.source.personal", fallback: "Personal")
    }
    public enum Title {
      /// Name (optional)
      public static let placeholder = L10n.tr("Localizable", "create.title.placeholder", fallback: "Name (optional)")
    }
  }
  public enum Favorite {
    /// Add to favorites
    public static let add = L10n.tr("Localizable", "favorite.add", fallback: "Add to favorites")
    /// Remove from favorites
    public static let remove = L10n.tr("Localizable", "favorite.remove", fallback: "Remove from favorites")
  }
  public enum Filters {
    /// Acidity
    public static let acidity = L10n.tr("Localizable", "filters.acidity", fallback: "Acidity")
    /// Character
    public static let character = L10n.tr("Localizable", "filters.character", fallback: "Character")
    /// Exclude flavors
    public static let exclude = L10n.tr("Localizable", "filters.exclude", fallback: "Exclude flavors")
    /// Mixes containing these flavors will be hidden
    public static let excludeHint = L10n.tr("Localizable", "filters.excludeHint", fallback: "Mixes containing these flavors will be hidden")
    /// For example, anise
    public static let excludePlaceholder = L10n.tr("Localizable", "filters.excludePlaceholder", fallback: "For example, anise")
    /// Freshness
    public static let freshness = L10n.tr("Localizable", "filters.freshness", fallback: "Freshness")
    /// Choose one or more
    public static let multiple = L10n.tr("Localizable", "filters.multiple", fallback: "Choose one or more")
    /// Flavor groups
    public static let profiles = L10n.tr("Localizable", "filters.profiles", fallback: "Flavor groups")
    /// Reset
    public static let reset = L10n.tr("Localizable", "filters.reset", fallback: "Reset")
    /// Show %lld mixes
    public static func showResultsLld(_ p1: Int) -> String {
      return L10n.tr("Localizable", "filters.showResults %lld", p1, fallback: "Show %lld mixes")
    }
    /// Strength
    public static let strength = L10n.tr("Localizable", "filters.strength", fallback: "Strength")
    /// Sweetness
    public static let sweetness = L10n.tr("Localizable", "filters.sweetness", fallback: "Sweetness")
    /// Find a mix
    public static let title = L10n.tr("Localizable", "filters.title", fallback: "Find a mix")
    public enum Empty {
      /// Try removing some criteria or reset the filters.
      public static let message = L10n.tr("Localizable", "filters.empty.message", fallback: "Try removing some criteria or reset the filters.")
      /// No mixes found
      public static let title = L10n.tr("Localizable", "filters.empty.title", fallback: "No mixes found")
    }
  }
  public enum Flavor {
    /// bergamot
    public static let bergamot = L10n.tr("Localizable", "flavor.bergamot", fallback: "bergamot")
    /// blackberry
    public static let blackberry = L10n.tr("Localizable", "flavor.blackberry", fallback: "blackberry")
    /// caramel
    public static let caramel = L10n.tr("Localizable", "flavor.caramel", fallback: "caramel")
    /// cinnamon
    public static let cinnamon = L10n.tr("Localizable", "flavor.cinnamon", fallback: "cinnamon")
    /// coffee
    public static let coffee = L10n.tr("Localizable", "flavor.coffee", fallback: "coffee")
    /// cooling
    public static let cool = L10n.tr("Localizable", "flavor.cool", fallback: "cooling")
    /// lemon
    public static let lemon = L10n.tr("Localizable", "flavor.lemon", fallback: "lemon")
    /// mango
    public static let mango = L10n.tr("Localizable", "flavor.mango", fallback: "mango")
    /// mint
    public static let mint = L10n.tr("Localizable", "flavor.mint", fallback: "mint")
    /// passion fruit
    public static let passionFruit = L10n.tr("Localizable", "flavor.passionFruit", fallback: "passion fruit")
    /// pear
    public static let pear = L10n.tr("Localizable", "flavor.pear", fallback: "pear")
    /// pomegranate
    public static let pomegranate = L10n.tr("Localizable", "flavor.pomegranate", fallback: "pomegranate")
    /// raspberry
    public static let raspberry = L10n.tr("Localizable", "flavor.raspberry", fallback: "raspberry")
    /// tea
    public static let tea = L10n.tr("Localizable", "flavor.tea", fallback: "tea")
    /// vanilla
    public static let vanilla = L10n.tr("Localizable", "flavor.vanilla", fallback: "vanilla")
  }
  public enum Home {
    /// Find the right mix
    public static let findMix = L10n.tr("Localizable", "home.findMix", fallback: "Find the right mix")
    /// Good evening
    public static let greeting = L10n.tr("Localizable", "home.greeting", fallback: "Good evening")
    /// From my stash
    public static let inventory = L10n.tr("Localizable", "home.inventory", fallback: "From my stash")
    /// Mix of the day
    public static let mixOfDay = L10n.tr("Localizable", "home.mixOfDay", fallback: "Mix of the day")
    /// Profile
    public static let profile = L10n.tr("Localizable", "home.profile", fallback: "Profile")
    /// What shall we mix today?
    public static let question = L10n.tr("Localizable", "home.question", fallback: "What shall we mix today?")
    /// Recommended today
    public static let recommended = L10n.tr("Localizable", "home.recommended", fallback: "Recommended today")
    /// Record a mix
    public static let record = L10n.tr("Localizable", "home.record", fallback: "Record a mix")
    public enum FindMix {
      /// By flavor, strength, and mood
      public static let subtitle = L10n.tr("Localizable", "home.findMix.subtitle", fallback: "By flavor, strength, and mood")
    }
  }
  public enum Intensity {
    /// Any
    public static let any = L10n.tr("Localizable", "intensity.any", fallback: "Any")
    /// Pronounced
    public static let pronounced = L10n.tr("Localizable", "intensity.pronounced", fallback: "Pronounced")
    /// Subtle
    public static let subtle = L10n.tr("Localizable", "intensity.subtle", fallback: "Subtle")
  }
  public enum Inventory {
    /// Add product
    public static let add = L10n.tr("Localizable", "inventory.add", fallback: "Add product")
    /// Custom product
    public static let addPrivate = L10n.tr("Localizable", "inventory.addPrivate", fallback: "Custom product")
    /// No products added yet
    public static let empty = L10n.tr("Localizable", "inventory.empty", fallback: "No products added yet")
    /// What can I make?
    public static let findMixes = L10n.tr("Localizable", "inventory.findMixes", fallback: "What can I make?")
    /// Tap an item to change its quantity.
    public static let hint = L10n.tr("Localizable", "inventory.hint", fallback: "Tap an item to change its quantity.")
    /// My inventory
    public static let title = L10n.tr("Localizable", "inventory.title", fallback: "My inventory")
    public enum Accessibility {
      /// Hides stock level choices
      public static let collapse = L10n.tr("Localizable", "inventory.accessibility.collapse", fallback: "Hides stock level choices")
      /// Shows stock level choices
      public static let expand = L10n.tr("Localizable", "inventory.accessibility.expand", fallback: "Shows stock level choices")
    }
    public enum Level {
      /// Out
      public static let empty = L10n.tr("Localizable", "inventory.level.empty", fallback: "Out")
      /// Low
      public static let low = L10n.tr("Localizable", "inventory.level.low", fallback: "Low")
      /// Plenty
      public static let plenty = L10n.tr("Localizable", "inventory.level.plenty", fallback: "Plenty")
    }
    public enum Private {
      /// Brand
      public static let brand = L10n.tr("Localizable", "inventory.private.brand", fallback: "Brand")
      /// Flavor
      public static let flavor = L10n.tr("Localizable", "inventory.private.flavor", fallback: "Flavor")
      /// Line (optional)
      public static let line = L10n.tr("Localizable", "inventory.private.line", fallback: "Line (optional)")
    }
    public enum Results {
      /// Missing one flavor
      public static let missing = L10n.tr("Localizable", "inventory.results.missing", fallback: "Missing one flavor")
      /// Ready to make
      public static let ready = L10n.tr("Localizable", "inventory.results.ready", fallback: "Ready to make")
      /// With a close substitute
      public static let substitution = L10n.tr("Localizable", "inventory.results.substitution", fallback: "With a close substitute")
      /// From my inventory
      public static let title = L10n.tr("Localizable", "inventory.results.title", fallback: "From my inventory")
      public enum Empty {
        /// Update your inventory to see available options.
        public static let message = L10n.tr("Localizable", "inventory.results.empty.message", fallback: "Update your inventory to see available options.")
        /// No suitable mixes
        public static let title = L10n.tr("Localizable", "inventory.results.empty.title", fallback: "No suitable mixes")
      }
    }
    public enum Sample {
      /// Missing: bergamot
      public static let missing = L10n.tr("Localizable", "inventory.sample.missing", fallback: "Missing: bergamot")
      /// Pear → green apple
      public static let substitution = L10n.tr("Localizable", "inventory.sample.substitution", fallback: "Pear → green apple")
    }
  }
  public enum Mix {
    /// Citrus Tea
    public static let citrusTea = L10n.tr("Localizable", "mix.citrusTea", fallback: "Citrus Tea")
    /// Composition
    public static let composition = L10n.tr("Localizable", "mix.composition", fallback: "Composition")
    /// Creamy Coffee
    public static let creamyCoffee = L10n.tr("Localizable", "mix.creamyCoffee", fallback: "Creamy Coffee")
    /// Forest Lemonade
    public static let forestLemonade = L10n.tr("Localizable", "mix.forestLemonade", fallback: "Forest Lemonade")
    /// Percentages refer to the total bowl.
    public static let percentageNote = L10n.tr("Localizable", "mix.percentageNote", fallback: "Percentages refer to the total bowl.")
    /// Rate
    public static let rate = L10n.tr("Localizable", "mix.rate", fallback: "Rate")
    /// %lld ratings
    public static func ratingsCountLld(_ p1: Int) -> String {
      return L10n.tr("Localizable", "mix.ratingsCount %lld", p1, fallback: "%lld ratings")
    }
    /// Red Garden
    public static let redGarden = L10n.tr("Localizable", "mix.redGarden", fallback: "Red Garden")
    /// Name or flavor
    public static let search = L10n.tr("Localizable", "mix.search", fallback: "Name or flavor")
    /// Southern Sunset
    public static let southernSunset = L10n.tr("Localizable", "mix.southernSunset", fallback: "Southern Sunset")
    /// Spiced Pear
    public static let spicedPear = L10n.tr("Localizable", "mix.spicedPear", fallback: "Spiced Pear")
    /// strength
    public static let strength = L10n.tr("Localizable", "mix.strength", fallback: "strength")
    /// your rating
    public static let yourRating = L10n.tr("Localizable", "mix.yourRating", fallback: "your rating")
  }
  public enum PersonalMix {
    /// Approximate profile
    public static let approximate = L10n.tr("Localizable", "personalMix.approximate", fallback: "Approximate profile")
  }
  public enum Profile {
    /// Berry
    public static let berry = L10n.tr("Localizable", "profile.berry", fallback: "Berry")
    /// Beverage
    public static let beverage = L10n.tr("Localizable", "profile.beverage", fallback: "Beverage")
    /// Citrus
    public static let citrus = L10n.tr("Localizable", "profile.citrus", fallback: "Citrus")
    /// Dessert
    public static let dessert = L10n.tr("Localizable", "profile.dessert", fallback: "Dessert")
    /// Cooling
    public static let fresh = L10n.tr("Localizable", "profile.fresh", fallback: "Cooling")
    /// Fruit
    public static let fruit = L10n.tr("Localizable", "profile.fruit", fallback: "Fruit")
    /// Herbal
    public static let herbal = L10n.tr("Localizable", "profile.herbal", fallback: "Herbal")
    /// Spicy
    public static let spicy = L10n.tr("Localizable", "profile.spicy", fallback: "Spicy")
  }
  public enum Rating {
    /// You can change your rating at any time
    public static let subtitle = L10n.tr("Localizable", "rating.subtitle", fallback: "You can change your rating at any time")
    /// How did you like this mix?
    public static let title = L10n.tr("Localizable", "rating.title", fallback: "How did you like this mix?")
  }
  public enum Results {
    /// Edit
    public static let edit = L10n.tr("Localizable", "results.edit", fallback: "Edit")
    /// Ideal matches
    public static let ideal = L10n.tr("Localizable", "results.ideal", fallback: "Ideal matches")
    /// You may also like
    public static let possible = L10n.tr("Localizable", "results.possible", fallback: "You may also like")
    /// Matching mixes
    public static let title = L10n.tr("Localizable", "results.title", fallback: "Matching mixes")
  }
  public enum Strength {
    /// Light
    public static let light = L10n.tr("Localizable", "strength.light", fallback: "Light")
    /// Medium
    public static let medium = L10n.tr("Localizable", "strength.medium", fallback: "Medium")
    /// Strong
    public static let strong = L10n.tr("Localizable", "strength.strong", fallback: "Strong")
  }
  public enum Tab {
    /// Articles
    public static let articles = L10n.tr("Localizable", "tab.articles", fallback: "Articles")
    /// My
    public static let collection = L10n.tr("Localizable", "tab.collection", fallback: "My")
    /// Create
    public static let create = L10n.tr("Localizable", "tab.create", fallback: "Create")
    /// Home
    public static let home = L10n.tr("Localizable", "tab.home", fallback: "Home")
    /// Mixes
    public static let mixes = L10n.tr("Localizable", "tab.mixes", fallback: "Mixes")
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
