import SwiftUI

struct SignedOutCollectionView: View {
    @EnvironmentObject private var navigation: AppNavigation
    @ObservedObject var model: CollectionViewModel

    var body: some View {
        NavigationStack {
            List {
                section(
                    title: L10n.Collection.personalMixes,
                    action: .personal,
                    destination: .personal
                )
                section(
                    title: L10n.Inventory.title,
                    action: .inventory,
                    destination: .inventory
                )
                section(
                    title: L10n.Collection.favorites,
                    action: .favorite,
                    destination: .favorites
                )
            }
            .scrollIndicators(.hidden)
            .navigationTitle(L10n.Tab.collection)
            .appScreenBackground()
        }
        .accessibilityIdentifier("screen.mySignedOut")
    }

    private func section(
        title: String,
        action: ProtectedAction,
        destination: CollectionDestination
    ) -> some View {
        SignedOutCollectionSection(title: title) {
            model.requestAccess(action) {
                navigation.openCollection(destination)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SignedOutCollectionView(model: CollectionViewModel(service: CollectionPreviewService()))
        .environmentObject(AppNavigation())
}
