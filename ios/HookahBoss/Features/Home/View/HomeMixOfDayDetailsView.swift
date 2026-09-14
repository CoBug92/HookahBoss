import SwiftUI

struct HomeMixOfDayDetailsView: View {
    let mix: MixPreview

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Margin.x4
        ) {
            Text(L10n.Home.mixOfDay)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(AppTheme.cream)
            Text(mix.title)
                .font(
                    .system(
                        size: .titleSize,
                        weight: .bold,
                        design: .serif
                    )
                )
                .tracking(.titleTracking)
                .lineLimit(2)
                .minimumScaleFactor(.titleMinimumScale)
            HStack(spacing: Margin.x3) {
                ForEach(Array(mix.flavorTags.prefix(3)), id: \.self) { tag in
                    Text(tag)
                        .font(
                            .system(
                                size: .tagFontSize,
                                weight: .semibold
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(.tagMinimumScale)
                        .padding(.horizontal, Margin.x4)
                        .padding(.vertical, Margin.x3)
                        .background(
                            .white.opacity(.tagBackgroundOpacity),
                            in: Capsule()
                        )
                }
            }
            HStack(spacing: Margin.x4) {
                Label(
                    mix.rating?.formatted(.number.precision(.fractionLength(1))) ?? L10n.Mix.noRatings,
                    systemImage: AppSymbol.ratingFilled
                )
                .accessibilityIdentifier("home.mixOfDay.rating")
                Spacer()
                Text(mix.strength.title)
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(.secondaryContentOpacity))
        }
        .foregroundStyle(.white)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let titleSize: CGFloat = 27
    static let titleTracking: CGFloat = -0.5
    static let titleMinimumScale: CGFloat = 0.78
    static let tagFontSize: CGFloat = 10
    static let tagMinimumScale: CGFloat = 0.75
}

private extension Double {
    static let tagBackgroundOpacity: Double = 0.16
    static let secondaryContentOpacity: Double = 0.72
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    HomeMixOfDayDetailsView(mix: HomePreviewData.mixOfDay)
        .padding(Margin.x9)
        .background(AppTheme.graphite)
}
