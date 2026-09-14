import Foundation

struct LibraryProjection: Equatable {
    var favorites: Set<UUID>
    var ratings: [UUID: Int]

    func overlaying(_ mutations: [LibraryMutation]) -> Self {
        var result = self
        for mutation in mutations {
            switch mutation.kind {
            case .favorite:
                if mutation.value == 1 {
                    result.favorites.insert(mutation.mixId)
                } else {
                    result.favorites.remove(mutation.mixId)
                }
            case .rating:
                result.ratings[mutation.mixId] = mutation.value
            }
        }
        return result
    }
}
