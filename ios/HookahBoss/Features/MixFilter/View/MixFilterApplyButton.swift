import SwiftUI

struct MixFilterApplyButton: View {
    let resultCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(L10n.Filters.showResultsLld(resultCount))
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Margin.x8)
                .foregroundStyle(.white)
                .background(
                    AppTheme.gold,
                    in: RoundedRectangle(
                        cornerRadius: .applyCornerRadius,
                        style: .continuous
                    )
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("filters.apply")
        .padding(.horizontal, Margin.x9)
        .padding(.vertical, Margin.x5)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let applyCornerRadius: CGFloat = 17
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    MixFilterApplyButton(resultCount: 24, action: {})
}
