import Foundation

struct PersonalMixRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String?
    var components: [PersonalMixComponentRecord]
    let createdAt: Date
    var isApproximate: Bool? = nil
}

struct PersonalMixComponentRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let source: ComponentSource
    let sourceID: String
    let brand: String?
    let line: String?
    let flavor: String
    var percentage: Int?
    var flavorProfiles: [String]? = nil
}

enum ComponentSource: String, Codable, CaseIterable {
    case catalog, personal, inventory
}

enum PercentageValidation: Equatable {
    case valid(effective: [Int?], automatic: Set<Int>)
    case noComponents
    case exceeds100
    case percentagesMustTotal100
    case insufficientRemainder
}

enum PercentageDistributor {
    static func validate(_ values: [Int?]) -> PercentageValidation {
        guard !values.isEmpty else { return .noComponents }
        guard values.allSatisfy({ $0 == nil || (1...100).contains($0!) }) else { return .exceeds100 }
        let entered = values.compactMap { $0 }.reduce(0, +)
        guard entered <= 100 else { return .exceeds100 }
        let emptyIndices = values.indices.filter { values[$0] == nil }
        if emptyIndices.count == values.count {
            let base = 100 / values.count, extra = 100 % values.count
            return .valid(effective: values.indices.map { base + ($0 < extra ? 1 : 0) }, automatic: Set(values.indices))
        }
        if emptyIndices.isEmpty {
            return entered == 100 ? .valid(effective: values, automatic: []) : .percentagesMustTotal100
        }
        let remainder = 100 - entered
        guard remainder >= emptyIndices.count else { return .insufficientRemainder }
        let base = remainder / emptyIndices.count
        let extra = remainder % emptyIndices.count
        var effective = values
        for (offset, index) in emptyIndices.enumerated() { effective[index] = base + (offset < extra ? 1 : 0) }
        return .valid(effective: effective, automatic: Set(emptyIndices))
    }
}
