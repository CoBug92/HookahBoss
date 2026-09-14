import SwiftUI

struct MixDetailContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let mix: MixPreview
    let personalRating: Int?
    let isPresented: Bool
    let onRate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x(11)) {
            MixDetailMetricsView(
                mix: mix,
                personalRating: personalRating,
                onRate: onRate
            )
            .opacity(isPresented ? 1 : .zero)
            .offset(y: isPresented ? .zero : Margin.x7)
            .animation(
                reduceMotion ? nil : .snappy.delay(.metricsDelay),
                value: isPresented
            )
            MixCompositionView(ingredients: mix.ingredients)
                .opacity(isPresented ? 1 : .zero)
                .offset(y: isPresented ? .zero : Margin.x7)
                .animation(
                    reduceMotion ? nil : .snappy.delay(.compositionDelay),
                    value: isPresented
                )
        }
        .padding(.horizontal, Margin.x9)
        .padding(.top, Margin.x(12))
        .padding(.bottom, Margin.x(16))
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: .detailsCornerRadius,
                topTrailingRadius: .detailsCornerRadius
            )
            .fill(AppTheme.background)
            .opacity(isPresented ? 1 : .zero)
            .offset(y: isPresented ? .zero : Margin.x7)
            .animation(
                reduceMotion ? nil : .snappy,
                value: isPresented
            )
        )
    }
}

// MARK: - Constants

private extension CGFloat {
    static let detailsCornerRadius: CGFloat = 28
}

private extension Double {
    static let metricsDelay: Double = 0.05
    static let compositionDelay: Double = 0.1
}

// MARK: - Preview

#Preview("Presented", traits: .sizeThatFitsLayout) {
    MixDetailContentView(
        mix: MixesPreviewData.featured,
        personalRating: 5,
        isPresented: true,
        onRate: {}
    )
}

#Preview("Before cascade", traits: .sizeThatFitsLayout) {
    MixDetailContentView(
        mix: MixesPreviewData.featured,
        personalRating: 5,
        isPresented: false,
        onRate: {}
    )
}
