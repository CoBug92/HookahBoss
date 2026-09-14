import SwiftUI

struct MixDetailMetricsView: View {
    let mix: MixPreview
    let personalRating: Int?
    let onRate: () -> Void

    var body: some View {
        HStack(spacing: .zero) {
            MixMetricView(
                value: mix.rating.map {
                    "★ " + $0.formatted(.number.precision(.fractionLength(1)))
                } ?? "—",
                caption: mix.ratingsCount > 0
                    ? L10n.Mix.ratingsCountLld(mix.ratingsCount)
                    : nil
            )
            Divider()
                .frame(height: .metricDividerHeight)
            MixMetricView(
                value: mix.strength.detailTitle,
                caption: L10n.Mix.strength
            )
            Divider()
                .frame(height: .metricDividerHeight)
            Button(action: onRate) {
                MixMetricView(
                    value: personalRatingValue,
                    caption: nil,
                    emphasized: personalRating == nil
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.Mix.yourRating))
            .accessibilityValue(Text(personalRatingAccessibilityValue))
        }
        .padding(.vertical, Margin.x7)
        .appCard(cornerRadius: .metricsCornerRadius)
    }

    private var personalRatingValue: String {
        guard let personalRating else { return L10n.Mix.rate }
        return "★ \(personalRating)"
    }

    private var personalRatingAccessibilityValue: String {
        guard let personalRating else { return L10n.Accessibility.notRated }
        return String(personalRating)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let metricDividerHeight: CGFloat = 34
    static let metricsCornerRadius: CGFloat = 18
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    MixDetailMetricsView(
        mix: MixesPreviewData.featured,
        personalRating: 5,
        onRate: {}
    )
    .padding(Margin.x8)
}
