import SwiftUI

struct ArticleDetailHeroView: View {
    let article: ArticleDTO
    let isAnimated: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ArticleSpecificArtwork(article: article)
                .scaleEffect(isAnimated ? .animatedScale : 1)
                .offset(
                    x: isAnimated ? -Margin.x3 : .zero,
                    y: isAnimated ? Margin.x2 : .zero
                )
                .animation(
                    .easeInOut(duration: .kenBurnsDuration),
                    value: isAnimated
                )

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(.gradientOpacity),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: Margin.x5) {
                Text(article.appCategory.title.uppercased())
                    .font(.caption2.bold())
                    .tracking(.categoryTracking)
                    .foregroundStyle(AppTheme.cream)

                Text(article.title)
                    .font(
                        .system(
                            size: .titleSize,
                            weight: .bold,
                            design: .serif
                        )
                    )
                    .foregroundStyle(.white)

                Label(
                    L10n.Articles.minutesLld(article.readingMinutes),
                    systemImage: AppSymbol.time
                )
                .font(.caption)
                .foregroundStyle(.white.opacity(.metadataOpacity))
            }
            .padding(.horizontal, Margin.x10)
            .padding(.bottom, Margin.x(23))
        }
        .frame(height: .height)
        .clipped()
    }
}

// MARK: - Constants

private extension CGFloat {
    static let animatedScale: CGFloat = 1.06
    static let categoryTracking: CGFloat = 1.2
    static let titleSize: CGFloat = 35
    static let height: CGFloat = 360
}

private extension Double {
    static let gradientOpacity: Double = 0.94
    static let metadataOpacity: Double = 0.8
    static let kenBurnsDuration: Double = 6
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    ArticleDetailHeroView(
        article: ArticleDetailPreviewData.article,
        isAnimated: true
    )
}
