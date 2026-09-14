enum AdminEntryVisibility {
    static func isVisible(isAuthenticated: Bool, isAdmin: Bool) -> Bool {
        isAuthenticated && isAdmin
    }
}
