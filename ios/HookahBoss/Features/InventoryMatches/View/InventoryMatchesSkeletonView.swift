import SwiftUI

struct InventoryMatchesSkeletonView: View {
    private let columns = [
        GridItem(.flexible(), spacing: Margin.x5),
        GridItem(.flexible(), spacing: Margin.x5),
    ]

    var body: some View {
        LazyVStack(alignment: .leading, spacing: Margin.x(12)) {
            section
            section
        }
        .padding(Margin.x8)
        .accessibilityHidden(true)
    }

    private var section: some View {
        VStack(alignment: .leading, spacing: Margin.x6) {
            RoundedRectangle(cornerRadius: .headingCornerRadius)
                .fill(AppTheme.elevated)
                .frame(width: .headingWidth, height: .headingHeight)

            LazyVGrid(columns: columns, spacing: Margin.x5) {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: .cardCornerRadius)
                        .fill(AppTheme.elevated)
                        .aspectRatio(.cardAspectRatio, contentMode: .fit)
                }
            }
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let headingCornerRadius: CGFloat = 6
    static let headingWidth: CGFloat = 180
    static let headingHeight: CGFloat = 26
    static let cardCornerRadius: CGFloat = 20
    static let cardAspectRatio: CGFloat = 0.86
}

// MARK: - Preview

#Preview("Light", traits: .sizeThatFitsLayout) {
    InventoryMatchesSkeletonView()
        .background(AppTheme.background)
        .preferredColorScheme(.light)
}

#Preview("Dark", traits: .sizeThatFitsLayout) {
    InventoryMatchesSkeletonView()
        .background(AppTheme.background)
        .preferredColorScheme(.dark)
}
