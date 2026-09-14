import SwiftUI

struct ArticleEditorialGrid: View {
    let articles: [ArticleDTO]

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width - Margin.x5

            HStack(alignment: .top, spacing: Margin.x5) {
                if let article = articles.first {
                    ArticleEditorialCard(
                        article: article,
                        height: .gridHeight,
                        prominent: true
                    )
                    .frame(width: availableWidth * .prominentWidthFraction)
                }

                VStack(spacing: Margin.x5) {
                    ForEach(Array(articles.dropFirst().prefix(2))) { article in
                        ArticleEditorialCard(
                            article: article,
                            height: (.gridHeight - Margin.x5) / 2,
                            prominent: false
                        )
                    }
                }
                .frame(width: availableWidth * .secondaryWidthFraction)
            }
        }
        .frame(height: .gridHeight)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let gridHeight: CGFloat = 258
    static let prominentWidthFraction: CGFloat = 0.56
    static let secondaryWidthFraction: CGFloat = 0.44
    static let previewWidth: CGFloat = 360
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    ArticleEditorialGrid(articles: ArticlesPreviewData.articles)
        .frame(width: .previewWidth)
        .padding(Margin.x5)
        .background(AppTheme.background)
}
