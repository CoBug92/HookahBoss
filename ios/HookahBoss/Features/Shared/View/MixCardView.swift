import SwiftUI

struct MixCardView: View {

    // MARK: - Properties

    let mix: MixPreview

    // MARK: - Computed properties

    private var ratingColor: Color {
        AppTheme.ratingColor(for: mix.personalRating)
    }

    // MARK: - Layout

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            MixArtwork(palette: mix.palette)

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(.gradientStartOpacity),
                    .black.opacity(.gradientMiddleOpacity),
                    .black.opacity(.gradientEndOpacity),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: Margin.x4) {
                Text(mix.title)
                    .font(
                        .system(
                            size: .titleSize,
                            weight: .bold,
                            design: .serif
                        )
                    )
                    .tracking(.titleTracking)
                    .lineLimit(3)
                    .minimumScaleFactor(.titleMinimumScale)
                    .multilineTextAlignment(.leading)

                FlavorCloud(tags: mix.flavorTags)

                HStack(spacing: Margin.x4) {
                    Label(
                        mix.rating?.formatted(.number.precision(.fractionLength(1))) ?? L10n.Mix.noRatings,
                        systemImage: AppSymbol.ratingFilled
                    )
                    Spacer(minLength: Margin.x2)
                    Text(mix.strength.title)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(.secondaryContentOpacity))
            }
            .foregroundStyle(.white)
            .padding(Margin.x7)

            VStack(spacing: Margin.x4) {
                HStack(
                    alignment: .top,
                    spacing: Margin.x4
                ) {
                    if let personalRating = mix.personalRating {
                        Label(
                            "\(personalRating)",
                            systemImage: AppSymbol.ratingFilled
                        )
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ratingColor)
                        .padding(.horizontal, Margin.x4)
                        .padding(.vertical, Margin.x3)
                        .background(
                            ratingColor.opacity(.ratingBackgroundOpacity),
                            in: RoundedRectangle(
                                cornerRadius: .ratingCornerRadius,
                                style: .continuous
                            )
                        )
                        .overlay {
                            RoundedRectangle(
                                cornerRadius: .ratingCornerRadius,
                                style: .continuous
                            )
                            .stroke(ratingColor, lineWidth: .borderWidth)
                        }
                    }

                    Spacer()

                    if mix.isFavorite {
                        Image(systemName: AppSymbol.favoriteFilled)
                            .font(
                                .system(
                                    size: .favoriteSize,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(.white)
                            .frame(height: .favoriteFrameHeight)
                            .shadow(
                                color: .black.opacity(.favoriteShadowOpacity),
                                radius: .favoriteShadowRadius,
                                y: Margin.x1
                            )
                            .accessibilityHidden(true)
                    }
                }
                Spacer()
            }
            .padding(Margin.x7)
        }
        .aspectRatio(.cardAspectRatio, contentMode: .fit)
        .clipShape(
            RoundedRectangle(
                cornerRadius: .cardCornerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: .cardCornerRadius,
                style: .continuous
            )
            .stroke(
                LinearGradient(
                    colors: [
                        ratingColor.opacity(mix.personalRating == nil ? 0.55 : 1),
                        .black,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: mix.personalRating == nil ? .borderWidth : .selectedBorderWidth
            )
        }
        .shadow(
            color: .black.opacity(.cardShadowOpacity),
            radius: .cardShadowRadius,
            y: Margin.x4
        )
        .mixTransitionSource(id: mix.id)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let previewWidth: CGFloat = 180
    static let titleSize: CGFloat = 22
    static let titleTracking: CGFloat = -0.6
    static let titleMinimumScale: CGFloat = 0.82
    static let ratingCornerRadius: CGFloat = 10
    static let borderWidth: CGFloat = 1
    static let selectedBorderWidth: CGFloat = 2
    static let favoriteSize: CGFloat = 18
    static let favoriteFrameHeight: CGFloat = 27
    static let favoriteShadowRadius: CGFloat = 3
    static let cardAspectRatio: CGFloat = 0.84
    static let cardCornerRadius: CGFloat = 20
    static let cardShadowRadius: CGFloat = 14
}

private extension Double {
    static let gradientStartOpacity: Double = 0.12
    static let gradientMiddleOpacity: Double = 0.62
    static let gradientEndOpacity: Double = 0.96
    static let secondaryContentOpacity: Double = 0.72
    static let ratingBackgroundOpacity: Double = 0.2
    static let favoriteShadowOpacity: Double = 0.5
    static let cardShadowOpacity: Double = 0.14
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    MixCardView(
        mix: MixPreview(
            id: UUID(),
            title: "Citrus Day",
            flavorTags: ["Lemon", "Mint"],
            flavorProfiles: [.citrus, .fresh],
            sweetness: .subtle,
            acidity: .pronounced,
            freshness: .pronounced,
            ingredients: [],
            rating: 4.7,
            ratingsCount: 42,
            strength: .medium,
            personalRating: 5,
            isFavorite: true,
            palette: .citrus
        )
    )
        .frame(width: .previewWidth)
        .padding(Margin.x5)
}
