import SwiftUI

struct FavoritesView: View {
    let mixes: [MixPreview]
    let title: String

    private let columns = [
        GridItem(
            .flexible(),
            spacing: Margin.x5
        ),
        GridItem(
            .flexible(),
            spacing: Margin.x5
        ),
    ]

    var body: some View {
        Group {
            if mixes.isEmpty {
                ContentUnavailableView(
                    L10n.Collection.Favorites.Empty.title,
                    systemImage: AppSymbol.favorite,
                    description: Text(L10n.Collection.Favorites.Empty.message)
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: Margin.x5) {
                        ForEach(mixes) { mix in
                            NavigationLink(value: mix) {
                                MixCardView(mix: mix)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Margin.x8)
                }
                .scrollIndicators(.hidden)
            }
        }
        .background(AppTheme.background)
        .navigationTitle(title)
    }
}

// MARK: - Preview

#Preview("Content") {
    NavigationStack {
        FavoritesView(
            mixes: MixesPreviewData.catalog,
            title: L10n.Collection.favorites
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        FavoritesView(mixes: [], title: L10n.Collection.favorites)
    }
}
