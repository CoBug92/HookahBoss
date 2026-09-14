import SwiftUI

struct MixCompositionView: View {
    let ingredients: [MixIngredient]

    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x6) {
            Text(L10n.Mix.composition)
                .font(.title3.weight(.semibold))
                .accessibilityIdentifier(AccessibilityID.mixComposition)

            LazyVGrid(columns: columns, spacing: Margin.x5) {
                ForEach(ingredients) { ingredient in
                    MixIngredientCard(ingredient: ingredient)
                }
            }
        }
    }
}

// MARK: - Constants

private extension MixCompositionView {
    var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Margin.x5),
            GridItem(.flexible(), spacing: Margin.x5),
        ]
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    MixCompositionView(ingredients: MixesPreviewData.featured.ingredients)
        .padding(Margin.x8)
}
