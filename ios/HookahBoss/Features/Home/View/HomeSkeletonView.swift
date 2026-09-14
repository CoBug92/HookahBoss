import SwiftUI

struct HomeSkeletonView: View {

    // MARK: - Properties

    private let columns = [
        GridItem(.flexible(), spacing: Margin.x6),
        GridItem(.flexible(), spacing: Margin.x6),
    ]

    // MARK: - Layout

    var body: some View {
        LazyVStack(alignment: .leading, spacing: Margin.x(12)) {
            SkeletonBlock(cornerRadius: .heroCornerRadius)
                .frame(height: .heroHeight)

            HStack(spacing: Margin.x5) {
                SkeletonBlock(cornerRadius: .quickActionCornerRadius)
                SkeletonBlock(cornerRadius: .quickActionCornerRadius)
            }
            .frame(height: .quickActionsHeight)

            VStack(alignment: .leading, spacing: Margin.x6) {
                SkeletonBlock(cornerRadius: .headingCornerRadius)
                    .frame(width: .headingWidth, height: .headingHeight)

                LazyVGrid(columns: columns, spacing: Margin.x6) {
                    SkeletonBlock(cornerRadius: .cardCornerRadius)
                        .frame(height: .cardHeight)
                    SkeletonBlock(cornerRadius: .cardCornerRadius)
                        .frame(height: .cardHeight)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct SkeletonBlock: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppTheme.elevated)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let heroCornerRadius: CGFloat = 26
    static let heroHeight: CGFloat = 280
    static let quickActionCornerRadius: CGFloat = 18
    static let quickActionsHeight: CGFloat = 114
    static let headingCornerRadius: CGFloat = 5
    static let headingWidth: CGFloat = 190
    static let headingHeight: CGFloat = 22
    static let cardCornerRadius: CGFloat = 20
    static let cardHeight: CGFloat = 198
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    HomeSkeletonView()
        .padding(Margin.x9)
        .background(AppTheme.background)
}
