import SwiftUI

struct CollectionCounterView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x5) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: .iconSize, height: .iconSize)
                .background(
                    AppTheme.gold.opacity(.iconBackgroundOpacity),
                    in: RoundedRectangle(cornerRadius: .iconCornerRadius)
                )
            Text(value)
                .font(.system(size: .valueFontSize, weight: .bold, design: .serif))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Margin.x7)
        .appCard(cornerRadius: .cardCornerRadius)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let iconSize: CGFloat = 34
    static let iconCornerRadius: CGFloat = 12
    static let valueFontSize: CGFloat = 26
    static let cardCornerRadius: CGFloat = 18
    static let previewWidth: CGFloat = 180
}

private extension Double {
    static let iconBackgroundOpacity = 0.9
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    CollectionCounterView(
        title: L10n.Collection.favorites,
        value: "12",
        icon: AppSymbol.favoriteFilled
    )
    .frame(width: .previewWidth)
    .padding(Margin.x8)
}
