import SwiftUI

struct PersonalMixDetailHeroView: View {
    let mix: PersonalMixRecord
    let title: String
    let componentsCount: Int
    let isApproximate: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PersonalMixArtwork(mix: mix)

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(.gradientOpacity),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: Margin.x4) {
                if isApproximate {
                    Label(
                        L10n.PersonalMix.approximate,
                        systemImage: AppSymbol.approximate
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.gold)
                }

                Text(title)
                    .font(
                        .system(
                            size: .titleFontSize,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                Text(L10n.Collection.componentsLld(componentsCount))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(.componentCountOpacity))
            }
            .padding(Margin.x10)
        }
        .frame(height: .height)
        .clipped()
    }
}

// MARK: - Constants

private extension CGFloat {
    static let titleFontSize: CGFloat = 34
    static let height: CGFloat = 280
}

private extension Double {
    static let gradientOpacity: Double = 0.88
    static let componentCountOpacity: Double = 0.72
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    PersonalMixDetailHeroView(
        mix: PersonalMixPreviewData.tropical,
        title: "Tropical Mix",
        componentsCount: 3,
        isApproximate: true
    )
}
