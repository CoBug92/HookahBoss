import SwiftUI

struct ArticleSectionView: View {
    let section: ArticleSectionDTO

    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x5) {
            Text(section.heading)
                .font(.title2.bold())

            Text(section.body)
                .font(.system(.body, design: .serif))
                .lineSpacing(Margin.x4)
                .foregroundStyle(.primary.opacity(.bodyTextOpacity))
        }
    }
}

// MARK: - Constants

private extension Double {
    static let bodyTextOpacity: Double = 0.82
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    ArticleSectionView(section: ArticleDetailPreviewData.detail.sections[0])
        .padding(Margin.x8)
        .background(AppTheme.background)
}
