import SwiftUI

struct HomeStatusView: View {

    // MARK: - Properties

    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    // MARK: - Layout

    var body: some View {
        VStack(spacing: Margin.x8) {
            ZStack {
                Circle()
                    .fill(AppTheme.gold.opacity(.haloOpacity))
                    .frame(
                        width: .haloSize,
                        height: .haloSize
                    )

                Circle()
                    .stroke(
                        AppTheme.gold.opacity(.ringOpacity),
                        lineWidth: .ringWidth
                    )
                    .frame(
                        width: .ringSize,
                        height: .ringSize
                    )

                Image(systemName: icon)
                    .font(
                        .system(
                            size: .iconSize,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(AppTheme.gold)
            }

            VStack(spacing: Margin.x3) {
                Text(title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            Button(action: action) {
                Label(
                    actionTitle,
                    systemImage: AppSymbol.sync
                )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(AppTheme.gold)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: .minimumHeight
        )
        .padding(.horizontal, Margin.x8)
        .padding(.vertical, Margin.x(12))
        .background {
            ZStack {
                AppTheme.card

                Circle()
                    .fill(AppTheme.gold.opacity(.decorationOpacity))
                    .frame(
                        width: .decorationSize,
                        height: .decorationSize
                    )
                    .offset(
                        x: Margin.x(55),
                        y: -Margin.x(45)
                    )
            }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: .cornerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: .cornerRadius,
                style: .continuous
            )
                .stroke(
                    AppTheme.gold.opacity(.borderOpacity),
                    lineWidth: .borderWidth
                )
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let haloSize: CGFloat = 104
    static let ringSize: CGFloat = 78
    static let ringWidth: CGFloat = 1
    static let iconSize: CGFloat = 32
    static let minimumHeight: CGFloat = 420
    static let decorationSize: CGFloat = 240
    static let cornerRadius: CGFloat = 28
    static let borderWidth: CGFloat = 1
}

private extension Double {
    static let haloOpacity: Double = 0.14
    static let ringOpacity: Double = 0.28
    static let decorationOpacity: Double = 0.06
    static let borderOpacity: Double = 0.16
}

// MARK: - Preview

#Preview("Empty", traits: .sizeThatFitsLayout) {
    HomeStatusView(
        icon: AppSymbol.mixing,
        title: L10n.Home.Empty.title,
        message: L10n.Home.Empty.message,
        actionTitle: L10n.Common.refresh,
        action: {}
    )
    .padding(Margin.x9)
    .background(AppTheme.background)
}

#Preview("Error", traits: .sizeThatFitsLayout) {
    HomeStatusView(
        icon: AppSymbol.retryUnavailable,
        title: L10n.Home.Error.title,
        message: L10n.Home.Error.message,
        actionTitle: L10n.Common.retry,
        action: {}
    )
    .padding(Margin.x9)
    .background(AppTheme.background)
}
