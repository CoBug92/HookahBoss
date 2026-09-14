import SwiftUI

@main
struct HookahBossApp: App {
    @AppStorage(StorageKey.hasConfirmedAdultAge) private var hasConfirmedAdultAge = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasConfirmedAdultAge {
                    RootView()
                } else {
                    AgeConfirmationView {
                        hasConfirmedAdultAge = true
                    }
                }
            }
            .scrollIndicators(.hidden)
            .preferredColorScheme(nil)
        }
    }
}

private enum StorageKey {
    static let hasConfirmedAdultAge = "hasConfirmedAdultAge"
}
