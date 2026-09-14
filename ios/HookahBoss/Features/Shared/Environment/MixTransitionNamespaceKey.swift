import SwiftUI

struct MixTransitionNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var mixTransitionNamespace: Namespace.ID? {
        get { self[MixTransitionNamespaceKey.self] }
        set { self[MixTransitionNamespaceKey.self] = newValue }
    }
}
