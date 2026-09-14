import SwiftUI

struct CollectionOverviewSection: View {
    let favoritesCount: Int
    let personalMixesCount: Int

    var body: some View {
        Section {
            HStack(spacing: Margin.x6) {
                NavigationLink(value: CollectionDestination.favorites) {
                    CollectionCounterView(
                        title: L10n.Collection.favorites,
                        value: String(favoritesCount),
                        icon: AppSymbol.favoriteFilled
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(value: CollectionDestination.personal) {
                    CollectionCounterView(
                        title: L10n.Collection.personalMixes,
                        value: String(personalMixesCount),
                        icon: AppSymbol.collection
                    )
                }
                .buttonStyle(.plain)
            }
            .listRowInsets(EdgeInsets())
        }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    List {
        CollectionOverviewSection(
            favoritesCount: 12,
            personalMixesCount: 4
        )
    }
}
