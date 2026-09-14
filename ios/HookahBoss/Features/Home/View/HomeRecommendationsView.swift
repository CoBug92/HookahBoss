import SwiftUI

struct HomeRecommendationsView: View {

    // MARK: - Properties

    let mixes: [MixPreview]
    private let columns = [
        GridItem(.flexible(), spacing: Margin.x6),
        GridItem(.flexible(), spacing: Margin.x6),
    ]

    // MARK: - Layout

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Margin.x6
        ) {
            Text(L10n.Home.recommended)
                .font(.title3.weight(.bold))

            LazyVGrid(
                columns: columns,
                spacing: Margin.x6
            ) {
                ForEach(mixes) { mix in
                    NavigationLink(value: mix) {
                        MixCardView(mix: mix)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityID.homeRecommendation(mix.id))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    NavigationStack {
        HomeRecommendationsView(mixes: HomePreviewData.recommendations)
            .padding(Margin.x9)
            .background(AppTheme.background)
    }
}
