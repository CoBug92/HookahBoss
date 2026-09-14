import SwiftUI

struct ArticlesSkeletonView: View {
    var body: some View {
        LazyVStack(
            alignment: .leading,
            spacing: Margin.x9
        ) {
            HStack(spacing: Margin.x5) {
                skeletonBlock(cornerRadius: .categoryCornerRadius)
                skeletonBlock(cornerRadius: .categoryCornerRadius)
                skeletonBlock(cornerRadius: .categoryCornerRadius)
            }
            .frame(height: .categoryHeight)

            skeletonBlock(cornerRadius: .headingCornerRadius)
                .frame(
                    width: .headingWidth,
                    height: .headingHeight
                )

            HStack(spacing: Margin.x5) {
                skeletonBlock(cornerRadius: .editorialCornerRadius)
                VStack(spacing: Margin.x5) {
                    skeletonBlock(cornerRadius: .editorialCornerRadius)
                    skeletonBlock(cornerRadius: .editorialCornerRadius)
                }
            }
            .frame(height: .editorialHeight)

            skeletonBlock(cornerRadius: .headingCornerRadius)
                .frame(
                    width: .secondaryHeadingWidth,
                    height: .headingHeight
                )

            ForEach(0..<Int.rowCount, id: \.self) { _ in
                skeletonBlock(cornerRadius: .rowCornerRadius)
                    .frame(height: .rowHeight)
            }
        }
        .accessibilityHidden(true)
    }

    private func skeletonBlock(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(
            cornerRadius: cornerRadius,
            style: .continuous
        )
        .fill(AppTheme.elevated)
    }
}

// MARK: - Constants

private extension Int {
    static let rowCount = 3
}

private extension CGFloat {
    static let categoryCornerRadius: CGFloat = 16
    static let categoryHeight: CGFloat = 92
    static let headingCornerRadius: CGFloat = 5
    static let headingWidth: CGFloat = 170
    static let secondaryHeadingWidth: CGFloat = 190
    static let headingHeight: CGFloat = 22
    static let editorialCornerRadius: CGFloat = 20
    static let editorialHeight: CGFloat = 258
    static let rowCornerRadius: CGFloat = 18
    static let rowHeight: CGFloat = 108
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    ArticlesSkeletonView()
        .padding(Margin.x8)
        .background(AppTheme.background)
        .preferredColorScheme(.light)
}
