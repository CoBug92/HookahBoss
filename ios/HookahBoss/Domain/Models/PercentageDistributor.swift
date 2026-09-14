enum PercentageDistributor {
    static func validate(_ values: [Int?]) -> PercentageValidation {
        guard !values.isEmpty else { return .noComponents }
        guard values.compactMap({ $0 }).allSatisfy({ (1...100).contains($0) }) else {
            return .exceeds100
        }

        let entered = values.compactMap { $0 }.reduce(0, +)
        guard entered <= 100 else { return .exceeds100 }
        let emptyIndices = values.indices.filter { values[$0] == nil }
        if emptyIndices.count == values.count {
            let base = 100 / values.count
            let extra = 100 % values.count
            return .valid(
                effective: values.indices.map { base + ($0 < extra ? 1 : 0) },
                automatic: Set(values.indices)
            )
        }
        if emptyIndices.isEmpty {
            return entered == 100 ? .valid(effective: values, automatic: []) : .percentagesMustTotal100
        }

        let remainder = 100 - entered
        guard remainder >= emptyIndices.count else { return .insufficientRemainder }
        let base = remainder / emptyIndices.count
        let extra = remainder % emptyIndices.count
        var effective = values
        for (offset, index) in emptyIndices.enumerated() {
            effective[index] = base + (offset < extra ? 1 : 0)
        }
        return .valid(effective: effective, automatic: Set(emptyIndices))
    }
}
