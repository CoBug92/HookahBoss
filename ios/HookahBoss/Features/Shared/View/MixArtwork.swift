import SwiftUI

struct MixArtwork: View {
    let palette: MixPalette

    var body: some View {
        ZStack {
            Image(ArtworkResource.resource(for: palette))
                .resizable()
                .scaledToFill()
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(.artworkGradientOpacity),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let artworkPreviewWidth: CGFloat = 320
    static let artworkPreviewHeight: CGFloat = 240
}

private extension Double {
    static let artworkGradientOpacity: Double = 0.22
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    MixArtwork(palette: .citrus)
//        .frame(
//            width: .artworkPreviewWidth,
//            height: .artworkPreviewHeight
//        )
}
