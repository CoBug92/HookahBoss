import SwiftUI

struct AgeConfirmationView: View {

    // MARK: - Properties

    let confirm: () -> Void

    // MARK: - Layout

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            backgroundDecoration
            content
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.age")
    }

    private var backgroundDecoration: some View {
        ZStack {
            Circle()
                .fill(AppTheme.gold.opacity(.goldDecorationOpacity))
                .frame(width: .largeDecorationSize, height: .largeDecorationSize)
                .blur(radius: .smallBlurRadius)
                .offset(
                    x: Margin.x(75),
                    y: -Margin.x(160)
                )
            Circle()
                .fill(Color.orange.opacity(.orangeDecorationOpacity))
                .frame(width: .smallDecorationSize, height: .smallDecorationSize)
                .blur(radius: .largeBlurRadius)
                .offset(
                    x: -Margin.x(80),
                    y: Margin.x(125)
                )
        }
        .accessibilityHidden(true)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: .zero) {
            brand
            Spacer()
            ageArtwork
            explanation
            Spacer()
            confirmation
        }
        .padding(.horizontal, Margin.x(11))
        .padding(.bottom, Margin.x7)
    }

    private var brand: some View {
        HStack(spacing: Margin.x5) {
            Image(systemName: AppSymbol.heat)
                .foregroundStyle(AppTheme.gold)
            Text(L10n.App.brand)
                .font(.caption.weight(.bold))
                .tracking(.brandTracking)
        }
        .padding(.top, Margin.x10)
    }

    private var ageArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: .artworkCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.artworkGradientStart, .artworkGradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .fill(Color.orange.opacity(.artworkGlowOpacity))
                .frame(width: .artworkGlowSize)
                .blur(radius: .artworkGlowBlurRadius)
                .offset(
                    x: Margin.x(55),
                    y: -Margin.x(38)
                )
            Image(systemName: AppSymbol.ageRestriction)
                .font(.system(size: .ageSymbolSize, weight: .light))
                .foregroundStyle(.white.opacity(.ageSymbolOpacity))
        }
        .frame(height: .artworkHeight)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: .artworkCornerRadius, style: .continuous))
        .shadow(
            color: .black.opacity(.shadowOpacity),
            radius: .shadowRadius,
            y: Margin.x7
        )
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: Margin.x6) {
            Text(L10n.Age.title)
                .font(.system(size: .titleFontSize, weight: .bold, design: .serif))
                .tracking(.titleTracking)
            Text(L10n.Age.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(Margin.x2)
        }
        .padding(.top, Margin.x(15))
    }

    private var confirmation: some View {
        VStack(spacing: Margin.x7) {
            Button(action: confirm) {
                Text(L10n.Age.confirm)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Margin.x9)
                    .foregroundStyle(.white)
                    .background(AppTheme.gold)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: Margin.x8,
                            style: .continuous
                        )
                    )
            }
            .accessibilityIdentifier(AccessibilityID.ageConfirm)
            Text(L10n.Age.notice)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let largeDecorationSize: CGFloat = 360
    static let smallDecorationSize: CGFloat = 300
    static let smallBlurRadius: CGFloat = 3
    static let largeBlurRadius: CGFloat = 30
    static let artworkCornerRadius: CGFloat = 34
    static let artworkGlowSize: CGFloat = 160
    static let artworkGlowBlurRadius: CGFloat = 20
    static let ageSymbolSize: CGFloat = 78
    static let artworkHeight: CGFloat = 245
    static let shadowRadius: CGFloat = 24
    static let titleFontSize: CGFloat = 38
    static let brandTracking: CGFloat = 1.8
    static let titleTracking: CGFloat = -1
}

private extension Double {
    static let goldDecorationOpacity = 0.13
    static let orangeDecorationOpacity = 0.09
    static let artworkGlowOpacity = 0.38
    static let ageSymbolOpacity = 0.94
    static let shadowOpacity = 0.2
}

private extension Color {
    static let artworkGradientStart = Color(.Brand.ageArtworkGradientStart)
    static let artworkGradientEnd = Color(.Brand.ageArtworkGradientEnd)
}

// MARK: - Preview

#Preview {
    AgeConfirmationView(confirm: {})
}
