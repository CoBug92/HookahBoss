import SwiftUI

struct MixIngredientCard: View {
    let ingredient: MixIngredient

    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x5) {
            Text("\(ingredient.percentage)%")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.gold)
            Divider()
            VStack(alignment: .leading, spacing: Margin.x2) {
                Text(ingredient.brandAndLine.uppercased())
                    .font(.caption2.weight(.medium))
                    .tracking(.ingredientTracking)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(ingredient.flavor)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(Margin.x7)
        .frame(
            maxWidth: .infinity,
            minHeight: .ingredientMinimumHeight,
            alignment: .topLeading
        )
        .background(AppTheme.card)
        .clipShape(
            RoundedRectangle(
                cornerRadius: .ingredientCornerRadius,
                style: .continuous
            )
        )
    }
}

// MARK: - Constants

private extension CGFloat {
    static let ingredientPreviewWidth: CGFloat = 180
    static let ingredientTracking: CGFloat = 0.4
    static let ingredientMinimumHeight: CGFloat = 132
    static let ingredientCornerRadius: CGFloat = 17
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    MixIngredientCard(ingredient: MixesPreviewData.featured.ingredients[0])
        .frame(width: .ingredientPreviewWidth)
        .padding(Margin.x5)
}
