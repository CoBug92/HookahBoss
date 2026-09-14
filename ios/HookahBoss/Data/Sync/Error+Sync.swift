extension Error {
    var isRetryableSyncFailure: Bool {
        if let apiError = self as? APIError,
           case .http(let status, _, _) = apiError {
            return status >= 500 || status == 408 || status == 429
        }
        if self is AuthTokenError { return false }
        return true
    }
}
