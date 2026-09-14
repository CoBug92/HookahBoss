import SwiftUI

struct CategoryCard: View {
    let category: ArticleCategory
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Image(systemName: AppSymbol.articleCategory(category))
                .font(.system(size: .iconSize, weight: .medium))
                .foregroundStyle(AppTheme.gold)

            Spacer(minLength: Margin.x3)

            Text(category.title)
                .font(.system(size: .titleSize, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(.minimumScale)

            Text(L10n.Articles.countLld(count))
                .font(.system(size: .countSize))
                .foregroundStyle(.secondary)
                .padding(.top, Margin.x2)
        }
        .padding(Margin.x6)
        .frame(
            width: .cardWidth,
            height: .cardHeight,
            alignment: .leading
        )
        .appCard(cornerRadius: .cornerRadius)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let iconSize: CGFloat = 19
    static let titleSize: CGFloat = 12
    static let countSize: CGFloat = 9
    static let minimumScale: CGFloat = 0.8
    static let cardWidth: CGFloat = 112
    static let cardHeight: CGFloat = 92
    static let cornerRadius: CGFloat = 16
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    CategoryCard(category: .preparation, count: 8)
        .padding(Margin.x5)
        .background(AppTheme.background)
}
