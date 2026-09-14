import SwiftUI

struct MixMetricView: View {
    let value: String
    let caption: String?
    var emphasized = false

    var body: some View {
        VStack(spacing: Margin.x2) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(emphasized ? AppTheme.gold : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(.metricMinimumScale)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(.metricMinimumScale)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

// MARK: - Constants

private extension CGFloat {
    static let metricMinimumScale: CGFloat = 0.75
    static let metricPreviewWidth: CGFloat = 120
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    MixMetricView(
        value: "★ 4.7",
        caption: L10n.Mix.ratingsCountLld(42)
    )
    .frame(width: .metricPreviewWidth)
    .padding(Margin.x5)
}
