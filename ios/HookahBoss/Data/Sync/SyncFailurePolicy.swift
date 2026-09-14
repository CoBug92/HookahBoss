enum SyncFailurePolicy {
    enum Disposition: Equatable {
        case queue
        case rollback
    }

    static func disposition(for error: Error) -> Disposition {
        error.isRetryableSyncFailure ? .queue : .rollback
    }
}
