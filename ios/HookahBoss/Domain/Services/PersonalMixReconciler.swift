enum PersonalMixReconciler {
    static func merge(
        server: [PersonalMixRecord],
        cached: [PersonalMixRecord],
        pending: [PersonalMixRecord]
    ) -> [PersonalMixRecord] {
        var result = server.map { remote in
            cached.first(where: { $0.id == remote.id }) ?? remote
        }
        for item in pending where !result.contains(where: { $0.id == item.id }) {
            result.insert(item, at: 0)
        }
        return result
    }
}
