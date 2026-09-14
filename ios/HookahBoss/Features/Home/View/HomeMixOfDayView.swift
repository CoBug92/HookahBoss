import SwiftUI

struct HomeMixOfDayView: View {
    let mix: MixPreview

    var body: some View {
        NavigationLink(value: mix) {
            MixArtwork(palette: mix.palette)
                .frame(maxWidth: .infinity)
                .frame(height: .heroHeight)
                .overlay {
                    LinearGradient(
                        colors: [
                            .black.opacity(.gradientStartOpacity),
                            .black.opacity(.gradientEndOpacity),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .overlay(alignment: .bottomLeading) {
                    HomeMixOfDayDetailsView(mix: mix)
                        .padding(Margin.x9)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .bottomLeading
                        )
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: .cornerRadius,
                        style: .continuous
                    )
                )
                .shadow(
                    color: .black.opacity(.shadowOpacity),
                    radius: .shadowRadius,
                    y: Margin.x5
                )
                .mixTransitionSource(id: mix.id)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.homeRecommendation(mix.id))
    }
}

// MARK: - Constants

private extension CGFloat {
    static let heroHeight: CGFloat = 280
    static let cornerRadius: CGFloat = 26
    static let shadowRadius: CGFloat = 20
}

private extension Double {
    static let gradientStartOpacity: Double = 0.06
    static let gradientEndOpacity: Double = 0.88
    static let shadowOpacity: Double = 0.16
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    NavigationStack {
        HomeMixOfDayView(mix: HomePreviewData.mixOfDay)
            .padding(Margin.x9)
    }
}
