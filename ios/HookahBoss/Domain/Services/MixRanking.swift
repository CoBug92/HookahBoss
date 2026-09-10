import Foundation

enum MixRanker {
    static func ranked(_ mixes:[MixPreview])->[MixPreview] {
        let order=Dictionary(uniqueKeysWithValues:mixes.enumerated().map{($0.element.id,$0.offset)})
        return mixes.sorted { lhs,rhs in
            let lp=personalSignal(lhs),rp=personalSignal(rhs)
            if lp != rp { return lp > rp }
            let lc=collectiveSignal(lhs),rc=collectiveSignal(rhs)
            if lc != rc { return lc > rc }
            return (order[lhs.id] ?? .max) < (order[rhs.id] ?? .max)
        }
    }
    static func mixOfDay(from mixes:[MixPreview],date:Date=Date(),calendar:Calendar = .current)->MixPreview? {
        guard !mixes.isEmpty else{return nil};let start=calendar.startOfDay(for:date);let day=calendar.dateComponents([.day],from:Date(timeIntervalSince1970:0),to:start).day ?? 0
        return mixes[abs(day) % mixes.count]
    }
    static func dailyRecommendations(
        from mixes: [MixPreview],
        limit: Int = 10,
        date: Date = Date(),
        calendar: Calendar = .current
    ) -> [MixPreview] {
        let rankedMixes = ranked(mixes)
        guard !rankedMixes.isEmpty, limit > 0 else { return [] }
        let day = calendar.dateComponents(
            [.day],
            from: Date(timeIntervalSince1970: 0),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        let offset = abs(day) % rankedMixes.count
        let rotated = Array(rankedMixes[offset...]) + Array(rankedMixes[..<offset])
        return Array(rotated.prefix(limit))
    }
    private static func personalSignal(_ mix:MixPreview)->Int {(mix.isFavorite ? 20:0)+(mix.personalRating ?? 0)*3}
    private static func collectiveSignal(_ mix:MixPreview)->Double {guard let rating=mix.rating else{return 0};let confidence=min(log10(Double(max(mix.ratingsCount,1))+1)/2,1);return rating*confidence}
}
