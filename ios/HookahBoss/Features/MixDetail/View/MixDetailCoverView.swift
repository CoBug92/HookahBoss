import SwiftUI

struct MixDetailCoverView: View {
    let palette: MixPalette
    let isAnimated: Bool

    var body: some View {
        ZStack {
            MixArtwork(palette: palette)
                .scaleEffect(isAnimated ? .kenBurnsScale : 1)
                .offset(
                    x: isAnimated ? -Margin.x3 : .zero,
                    y: isAnimated ? Margin.x2 : .zero
                )
                .animation(
                    .easeInOut(duration: .kenBurnsDuration),
                    value: isAnimated
                )
            LinearGradient(
                stops: [
                    .init(
                        color: .black.opacity(.coverGradientOpacity),
                        location: .zero
                    ),
                    .init(
                        color: .clear,
                        location: .coverGradientEndLocation
                    ),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(
            maxWidth: .infinity,
            minHeight: .coverHeight,
            maxHeight: .coverHeight
        )
        .clipped()
    }
}

// MARK: - Constants

private extension CGFloat {
    static let coverHeight: CGFloat = 410
    static let coverGradientEndLocation: CGFloat = 0.42
    static let kenBurnsScale: CGFloat = 1.06
}

private extension Double {
    static let coverGradientOpacity: Double = 0.36
    static let kenBurnsDuration: Double = 6
}

// MARK: - Preview

#Preview("Ken Burns", traits: .sizeThatFitsLayout) {
    MixDetailCoverView(
        palette: .citrus,
        isAnimated: true
    )
}

#Preview("Static", traits: .sizeThatFitsLayout) {
    MixDetailCoverView(
        palette: .citrus,
        isAnimated: false
    )
}
