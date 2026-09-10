import XCTest

final class ArchitectureGuardTests: XCTestCase {
    func testFeaturesDoNotDependOnConcreteInfrastructure() throws {
        let featuresDirectory = try RepositoryLayout.featuresDirectory(from: #filePath)
        let featureSources = try RepositoryLayout.swiftSources(below: featuresDirectory)

        XCTAssertFalse(featureSources.isEmpty, "Architecture guard found no feature sources at \(featuresDirectory.path)")

        let forbiddenReferences = [
            #"\bAPIClient\b"#,
            #"\bURLSession\b"#,
            #"\bUserDefaults\b"#,
            #"\bFileManager\b"#,
            #"\bModelContext\b"#,
            #"\bNSPersistent(?:Container|Context|StoreCoordinator)\b"#,
            #"\bKeychain\w*\b"#,
            #"\bSecItem\w*\b"#,
        ]
        let expressions = try forbiddenReferences.map { try NSRegularExpression(pattern: $0) }
        var violations: [String] = []

        for sourceURL in featureSources {
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            let sourceRange = NSRange(source.startIndex..., in: source)
            for expression in expressions {
                for match in expression.matches(in: source, range: sourceRange) {
                    guard let range = Range(match.range, in: source) else { continue }
                    let line = source[..<range.lowerBound].reduce(into: 1) { count, character in
                        if character == "\n" { count += 1 }
                    }
                    let relativePath = sourceURL.path.replacingOccurrences(
                        of: featuresDirectory.deletingLastPathComponent().path + "/",
                        with: ""
                    )
                    violations.append("\(relativePath):\(line): \(source[range])")
                }
            }
        }

        XCTAssertTrue(
            violations.isEmpty,
            "Feature code must depend on protocols/domain abstractions, not concrete network or persistence types:\n"
                + violations.sorted().joined(separator: "\n")
        )
    }

    func testCreateMixViewsOnlyRenderStateAndForwardIntents() throws {
        let featuresDirectory = try RepositoryLayout.featuresDirectory(from: #filePath)
        let createMixDirectory = featuresDirectory.appendingPathComponent("CreateMix", isDirectory: true)
        let viewSources = try RepositoryLayout.swiftSources(below: createMixDirectory)
            .filter { $0.lastPathComponent.hasSuffix("View.swift") }
        let forbidden = try [
            #"\b(?:APIClient|PublicContentStore|PersonalMixStore|InventoryStore|AuthRuntime)\b"#,
            #"\bTask\s*\{"#,
            #"\.task\s*\{"#,
            #"\.(?:loadOptions|privateProducts|addSynced|configure)\s*\("#,
        ].map { try NSRegularExpression(pattern: $0) }
        var violations: [String] = []
        for sourceURL in viewSources {
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            let range = NSRange(source.startIndex..., in: source)
            for expression in forbidden where expression.firstMatch(in: source, range: range) != nil {
                violations.append("\(sourceURL.lastPathComponent): \(expression.pattern)")
            }
        }
        XCTAssertFalse(viewSources.isEmpty)
        XCTAssertTrue(violations.isEmpty, "CreateMix views may only bind rendered state and forward intents:\n\(violations.joined(separator: "\n"))")
    }

    func testPublicFeatureViewsDoNotReachServicesOrPerformBusinessRules() throws {
        let features = try RepositoryLayout.featuresDirectory(from: #filePath)
        let directories = ["Home", "Mixes", "Articles"]
        let patterns = try [
            #"\b(?:APIClient|PublicContentStore|AuthRuntime)\b"#,
            #"\.(?:load|setArticleBookmark|setFavorite|setRating)\s*\("#,
            #"MixRanker\.|\.matchQuality\s*\("#,
            #"\bTask\s*\{"#,
        ].map { try NSRegularExpression(pattern: $0) }
        var violations: [String] = []
        for directory in directories {
            let sources = try RepositoryLayout.swiftSources(below: features.appendingPathComponent(directory))
                .filter { $0.lastPathComponent.hasSuffix("View.swift") }
            for url in sources {
                let source = try String(contentsOf: url, encoding: .utf8)
                let range = NSRange(source.startIndex..., in: source)
                for pattern in patterns where pattern.firstMatch(in: source, range: range) != nil {
                    violations.append("\(directory)/\(url.lastPathComponent): \(pattern.pattern)")
                }
            }
        }
        XCTAssertTrue(violations.isEmpty, "Public feature views must only bind state and forward intents:\n\(violations.joined(separator: "\n"))")
    }

    func testInventoryMatchViewDoesNotPerformInfrastructureOrAsyncWork() throws {
        let features = try RepositoryLayout.featuresDirectory(from: #filePath)
        let sourceURL = features.appendingPathComponent("Collection/CollectionComponents.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        let start = try XCTUnwrap(source.range(of: "struct InventoryMixResultsView"))
        let matchViewSource = String(source[start.lowerBound...])
        for pattern in [#"\b(?:APIClient|AuthRuntime|InventoryMatchCache)\b"#, #"\bTask\s*\{"#, #"\.task\s*\{"#, #"\.inventoryMatches\s*\("#] {
            XCTAssertNil(matchViewSource.range(of: pattern, options: .regularExpression), "Inventory results view contains forbidden operation: \(pattern)")
        }
    }

    func testAdminViewsOnlyBindViewModelsAndForwardIntents() throws {
        let features = try RepositoryLayout.featuresDirectory(from: #filePath)
        let sources = try RepositoryLayout.swiftSources(below: features.appendingPathComponent("Admin"))
            .filter { $0.lastPathComponent.hasSuffix("View.swift") }
        let forbidden = try [#"\.admin(?:List|Create|Update|Delete)\s*\("#, #"\bTask\s*\{"#, #"\.task\s*\{"#, #"AdminFormValidator\.|AdminAggregateMapper\."#].map { try NSRegularExpression(pattern: $0) }
        var violations:[String]=[]
        for url in sources { let source=try String(contentsOf:url,encoding:.utf8),range=NSRange(source.startIndex...,in:source);for pattern in forbidden where pattern.firstMatch(in:source,range:range) != nil { violations.append("\(url.lastPathComponent): \(pattern.pattern)") } }
        XCTAssertTrue(violations.isEmpty,"Admin views contain business/service orchestration:\n\(violations.joined(separator:"\n"))")
    }

    func testCollectionViewsDoNotReachStoresAuthOrSpawnTasks() throws {
        let features = try RepositoryLayout.featuresDirectory(from: #filePath)
        let directory = features.appendingPathComponent("Collection", isDirectory: true)
        let viewSources = try RepositoryLayout.swiftSources(below: directory).filter { $0.lastPathComponent.hasSuffix("View.swift") || $0.lastPathComponent == "CollectionComponents.swift" }
        let patterns = [#"\b(?:APIClient|AuthRuntime|PublicContentStore|InventoryStore|PersonalMixStore|InventoryMatchCache)\b"#, #"\bTask\s*\{"#, #"\.task\s*\{"#]
        var violations: [String] = []
        for url in viewSources { let source = try String(contentsOf: url, encoding: .utf8); for pattern in patterns where source.range(of: pattern, options: .regularExpression) != nil { violations.append("\(url.lastPathComponent): \(pattern)") } }
        XCTAssertTrue(violations.isEmpty, "Collection views must only render VM state and intents:\n\(violations.joined(separator: "\n"))")
    }

    func testProductionViewsUseGeneratedLocalizationSymbols() throws {
        let features = try RepositoryLayout.featuresDirectory(from: #filePath)
        let sourceRoot = features.deletingLastPathComponent()
        let stringsURL = sourceRoot.appendingPathComponent("Resources/Localization/en.lproj/Localizable.strings")
        let strings = try String(contentsOf: stringsURL, encoding: .utf8)
        let keyExpression = try NSRegularExpression(pattern: #"(?m)^\s*\"([^\"]+)\"\s*="#)
        let keys = Set(keyExpression.matches(in: strings, range: NSRange(strings.startIndex..., in: strings)).compactMap { match in
            Range(match.range(at: 1), in: strings).map { String(strings[$0]) }
        })
        let formattedKeyPrefixes = keys.compactMap { key -> String? in
            guard let marker = key.firstIndex(of: "%") else { return nil }
            return String(key[..<marker])
        }
        let literalExpression = try NSRegularExpression(pattern: #"\"([^\"\\]*(?:\\.[^\"\\]*)*)\""#)
        let viewSources = try RepositoryLayout.swiftSources(below: features).filter {
            (try? String(contentsOf: $0, encoding: .utf8).contains(": View")) == true
        }
        var violations: [String] = []

        for url in viewSources {
            let source = try String(contentsOf: url, encoding: .utf8)
            if source.contains("String.LocalizationValue(") || source.contains("String(localized:") {
                violations.append("\(url.lastPathComponent): dynamic localization bypass")
            }
            for prefix in formattedKeyPrefixes where source.contains("\"\(prefix)\\(") {
                violations.append("\(url.lastPathComponent): raw interpolated key \(prefix)")
            }
            for match in literalExpression.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
                guard let range = Range(match.range(at: 1), in: source) else { continue }
                let literal = String(source[range])
                if keys.contains(literal) { violations.append("\(url.lastPathComponent): raw key \(literal)") }
            }
        }

        XCTAssertFalse(viewSources.isEmpty)
        XCTAssertTrue(violations.isEmpty, "Production views must use generated L10n symbols:\n\(violations.sorted().joined(separator: "\n"))")
    }

    func testProductionSwiftDoesNotUseRawArtworkFilenames() throws {
        let features = try RepositoryLayout.featuresDirectory(from: #filePath)
        let sourceRoot = features.deletingLastPathComponent()
        let sources = try RepositoryLayout.swiftSources(below: sourceRoot).filter {
            !$0.path.contains("/Generated/")
        }
        let expression = try NSRegularExpression(pattern: #"\"(?:mix|article)-[a-z0-9-]+\""#)
        var violations: [String] = []
        for url in sources {
            let source = try String(contentsOf: url, encoding: .utf8)
            if expression.firstMatch(in: source, range: NSRange(source.startIndex..., in: source)) != nil {
                violations.append(url.lastPathComponent)
            }
        }
        XCTAssertTrue(violations.isEmpty, "Artwork must be resolved through typed AssetFiles: \(violations.sorted())")
    }
}

private enum RepositoryLayout {
    static func featuresDirectory(from testFilePath: String) throws -> URL {
        var ancestor = URL(fileURLWithPath: testFilePath).deletingLastPathComponent()
        let fileManager = FileManager.default

        while ancestor.path != "/" {
            let candidates = [
                ancestor.appendingPathComponent("HookahBoss/Features", isDirectory: true),
                ancestor.appendingPathComponent("Sources/HookahBoss/Features", isDirectory: true),
                ancestor.appendingPathComponent("Sources/Features", isDirectory: true),
                ancestor.appendingPathComponent("Features", isDirectory: true),
            ]
            if let match = candidates.first(where: { fileManager.fileExists(atPath: $0.path) }) {
                return match
            }
            ancestor.deleteLastPathComponent()
        }

        throw LayoutError.featuresDirectoryNotFound(startingAt: testFilePath)
    }

    static func swiftSources(below directory: URL) throws -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw LayoutError.cannotEnumerate(directory)
        }

        return enumerator.compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" }
            .sorted { $0.path < $1.path }
    }

    enum LayoutError: LocalizedError {
        case featuresDirectoryNotFound(startingAt: String)
        case cannotEnumerate(URL)

        var errorDescription: String? {
            switch self {
            case .featuresDirectoryNotFound(let path):
                "Could not locate the app's Features directory while walking up from \(path)"
            case .cannotEnumerate(let directory):
                "Could not enumerate feature sources below \(directory.path)"
            }
        }
    }
}
