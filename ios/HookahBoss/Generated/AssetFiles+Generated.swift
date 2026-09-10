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
  /// mix-dessert.png
  internal static let mixDessertPng = File(name: "mix-dessert", ext: "png", relativePath: "", mimeType: "image/png")
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
