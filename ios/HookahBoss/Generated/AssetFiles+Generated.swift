// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length line_length implicit_return

// MARK: - Files

// swiftlint:disable explicit_type_interface identifier_name
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum AssetFiles {
  /// article-basics.png
  internal static let articleBasicsPng = File(name: "article-basics", ext: "png", relativePath: "", mimeType: "image/png")
  /// article-care.png
  internal static let articleCarePng = File(name: "article-care", ext: "png", relativePath: "", mimeType: "image/png")
  /// article-heat.png
  internal static let articleHeatPng = File(name: "article-heat", ext: "png", relativePath: "", mimeType: "image/png")
  /// article-preparation.png
  internal static let articlePreparationPng = File(name: "article-preparation", ext: "png", relativePath: "", mimeType: "image/png")
  /// article-safety.png
  internal static let articleSafetyPng = File(name: "article-safety", ext: "png", relativePath: "", mimeType: "image/png")
  /// mix-berry-citrus.png
  internal static let mixBerryCitrusPng = File(name: "mix-berry-citrus", ext: "png", relativePath: "", mimeType: "image/png")
  /// mix-berry-v2.png
  internal static let mixBerryV2Png = File(name: "mix-berry-v2", ext: "png", relativePath: "", mimeType: "image/png")
  /// mix-beverage-v2.png
  internal static let mixBeverageV2Png = File(name: "mix-beverage-v2", ext: "png", relativePath: "", mimeType: "image/png")
  /// mix-citrus-v2.png
  internal static let mixCitrusV2Png = File(name: "mix-citrus-v2", ext: "png", relativePath: "", mimeType: "image/png")
  /// mix-dessert.png
  internal static let mixDessertPng = File(name: "mix-dessert", ext: "png", relativePath: "", mimeType: "image/png")
  /// mix-dessert-v2.png
  internal static let mixDessertV2Png = File(name: "mix-dessert-v2", ext: "png", relativePath: "", mimeType: "image/png")
  /// mix-fresh-v2.png
  internal static let mixFreshV2Png = File(name: "mix-fresh-v2", ext: "png", relativePath: "", mimeType: "image/png")
  /// mix-fruit-v2.png
  internal static let mixFruitV2Png = File(name: "mix-fruit-v2", ext: "png", relativePath: "", mimeType: "image/png")
  /// mix-herbal-v2.png
  internal static let mixHerbalV2Png = File(name: "mix-herbal-v2", ext: "png", relativePath: "", mimeType: "image/png")
  /// mix-spicy-v2.png
  internal static let mixSpicyV2Png = File(name: "mix-spicy-v2", ext: "png", relativePath: "", mimeType: "image/png")
  /// mix-tropical.png
  internal static let mixTropicalPng = File(name: "mix-tropical", ext: "png", relativePath: "", mimeType: "image/png")
}
// swiftlint:enable explicit_type_interface identifier_name
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

internal struct File {
  internal let name: String
  internal let ext: String?
  internal let relativePath: String
  internal let mimeType: String

  internal var url: URL {
    return url(locale: nil)
  }

  internal func url(locale: Locale?) -> URL {
    let bundle = BundleToken.bundle
    let url = bundle.url(
      forResource: name,
      withExtension: ext,
      subdirectory: relativePath,
      localization: locale?.identifier
    )
    guard let result = url else {
      let file = name + (ext.flatMap { ".\($0)" } ?? "")
      fatalError("Could not locate file named \(file)")
    }
    return result
  }

  internal var path: String {
    return path(locale: nil)
  }

  internal func path(locale: Locale?) -> String {
    return url(locale: locale).path
  }
}

// swiftlint:disable convenience_type explicit_type_interface
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type explicit_type_interface
