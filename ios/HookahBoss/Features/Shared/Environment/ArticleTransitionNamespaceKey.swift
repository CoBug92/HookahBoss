import SwiftUI

struct ArticleTransitionNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var articleTransitionNamespace: Namespace.ID? {
        get { self[ArticleTransitionNamespaceKey.self] }
        set { self[ArticleTransitionNamespaceKey.self] = newValue }
    }
}
