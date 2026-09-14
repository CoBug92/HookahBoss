import SwiftUI

struct ArticleDetailSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x6) {
            RoundedRectangle(cornerRadius: .lineCornerRadius)
                .fill(AppTheme.elevated)
                .frame(height: .summaryHeight)

            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: Margin.x4) {
                    RoundedRectangle(cornerRadius: .lineCornerRadius)
                        .fill(AppTheme.elevated)
                        .frame(width: .headingWidth, height: .headingHeight)

                    RoundedRectangle(cornerRadius: .lineCornerRadius)
                        .fill(AppTheme.elevated)
                        .frame(height: .paragraphHeight)
                }
            }
        }
        .padding(Margin.x10)
        .background(AppTheme.background)
        .redacted(reason: .placeholder)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let lineCornerRadius: CGFloat = 8
    static let summaryHeight: CGFloat = 72
    static let headingWidth: CGFloat = 210
    static let headingHeight: CGFloat = 28
    static let paragraphHeight: CGFloat = 112
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    ArticleDetailSkeletonView()
}
