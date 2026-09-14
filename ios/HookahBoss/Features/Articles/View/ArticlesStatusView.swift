import SwiftUI

struct ArticlesStatusView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: Margin.x8) {
            Image(systemName: icon)
                .font(
                    .system(
                        size: .iconSize,
                        weight: .medium
                    )
                )
                .foregroundStyle(AppTheme.gold)
                .frame(
                    width: .iconBackgroundSize,
                    height: .iconBackgroundSize
                )
                .background(
                    AppTheme.gold.opacity(.iconBackgroundOpacity),
                    in: Circle()
                )

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
        .appCard(cornerRadius: .cornerRadius)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let iconSize: CGFloat = 32
    static let iconBackgroundSize: CGFloat = 88
    static let minimumHeight: CGFloat = 420
    static let cornerRadius: CGFloat = 28
}

private extension Double {
    static let iconBackgroundOpacity: Double = 0.14
}

// MARK: - Preview

#Preview("Empty", traits: .sizeThatFitsLayout) {
    ArticlesStatusView(
        icon: AppSymbol.article,
        title: L10n.Articles.Empty.title,
        message: L10n.Articles.Empty.message,
        actionTitle: L10n.Common.refresh,
        action: {}
    )
    .padding(Margin.x8)
    .background(AppTheme.background)
}

#Preview("Error", traits: .sizeThatFitsLayout) {
    ArticlesStatusView(
        icon: AppSymbol.retryUnavailable,
        title: L10n.Articles.Error.title,
        message: L10n.Articles.Error.message,
        actionTitle: L10n.Common.retry,
        action: {}
    )
    .padding(Margin.x8)
    .background(AppTheme.background)
}
