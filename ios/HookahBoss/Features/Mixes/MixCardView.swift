import SwiftUI
struct MixCardView: View {
    let mix: MixPreview

    private var ratingColor: Color {
        AppTheme.ratingColor(for: mix.personalRating)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            MixArtwork(palette: mix.palette)

            LinearGradient(
                colors: [.clear, .black.opacity(0.12), .black.opacity(0.62), .black.opacity(0.96)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(mix.title)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .tracking(-0.6)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
                    .multilineTextAlignment(.leading)

                FlavorCloud(tags: mix.flavorTags)

                HStack {
                    if let rating = mix.rating {
                        Label(rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                    }
                    Spacer(minLength: 4)
                    Text(mix.strength.title)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
            }
            .foregroundStyle(.white)
            .padding(14)

            VStack {
                HStack(alignment: .top) {
                    if let personalRating = mix.personalRating {
                        Label("\(personalRating)", systemImage: "star.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ratingColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(ratingColor.opacity(0.2), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(ratingColor, lineWidth: 1)
                            }
                    }

                    Spacer()

                    Image(systemName: mix.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(height: 27)
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
                        .accessibilityHidden(true)
                }
                Spacer()
            }
            .padding(14)
        }
        .aspectRatio(0.84, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [ratingColor.opacity(mix.personalRating == nil ? 0.55 : 1), .black],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: mix.personalRating == nil ? 1 : 2
                )
        }
        .shadow(color:.black.opacity(0.14),radius:14,y:7)
        .accessibilityElement(children: .combine)
    }
}
