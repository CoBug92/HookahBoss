import SwiftUI

struct ArticleDetailContentView: View {
    let detail: ArticleDetailDTO
    let isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x(13)) {
            Text(detail.summary)
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
                .lineSpacing(Margin.x3)

            ForEach(Array(detail.sections.enumerated()), id: \.offset) { index, section in
                ArticleSectionView(section: section)
                    .opacity(isPresented ? 1 : .zero)
                    .offset(y: isPresented ? .zero : Margin.x6)
                    .animation(
                        .easeOut(duration: .sectionDuration)
                            .delay(Double(index) * .sectionDelay),
                        value: isPresented
                    )
            }

            if !detail.related.isEmpty {
                RelatedArticlesView(articles: detail.related)
                    .opacity(isPresented ? 1 : .zero)
                    .offset(y: isPresented ? .zero : Margin.x6)
                    .animation(
                        .easeOut(duration: .sectionDuration)
                            .delay(Double(detail.sections.count) * .sectionDelay),
                        value: isPresented
                    )
            }
        }
        .padding(Margin.x10)
        .background(
            AppTheme.background,
            in: UnevenRoundedRectangle(
                topLeadingRadius: .cornerRadius,
                topTrailingRadius: .cornerRadius
            )
        )
        .offset(y: -Margin.x(12))
    }
}

// MARK: - Constants

private extension CGFloat {
    static let cornerRadius: CGFloat = 28
}

private extension Double {
    static let sectionDuration: Double = 0.25
    static let sectionDelay: Double = 0.05
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    ArticleDetailContentView(
        detail: ArticleDetailPreviewData.detail,
        isPresented: true
    )
    .background(AppTheme.background)
}
