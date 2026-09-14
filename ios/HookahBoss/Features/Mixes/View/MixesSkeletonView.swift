import SwiftUI

struct MixesSkeletonView: View {

    // MARK: - Computed properties

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Margin.x6),
            GridItem(.flexible(), spacing: Margin.x6),
        ]
    }

    // MARK: - Layout

    var body: some View {
        LazyVGrid(columns: columns, spacing: Margin.x6) {
            ForEach(0..<Int.skeletonCardCount, id: \.self) { _ in
                RoundedRectangle(
                    cornerRadius: .cardCornerRadius,
                    style: .continuous
                )
                .fill(AppTheme.elevated)
                .aspectRatio(.cardAspectRatio, contentMode: .fit)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension Int {
    static let skeletonCardCount = 6
}

private extension CGFloat {
    static let cardCornerRadius: CGFloat = 20
    static let cardAspectRatio: CGFloat = 0.84
}

// MARK: - Preview

#Preview("Light", traits: .sizeThatFitsLayout) {
    MixesSkeletonView()
        .padding(Margin.x8)
        .background(AppTheme.background)
        .preferredColorScheme(.light)
}

#Preview("Dark", traits: .sizeThatFitsLayout) {
    MixesSkeletonView()
        .padding(Margin.x8)
        .background(AppTheme.background)
        .preferredColorScheme(.dark)
}
