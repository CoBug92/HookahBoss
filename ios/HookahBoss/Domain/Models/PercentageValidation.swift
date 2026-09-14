enum PercentageValidation: Equatable {
    case valid(effective: [Int?], automatic: Set<Int>)
    case noComponents
    case exceeds100
    case percentagesMustTotal100
    case insufficientRemainder
}
