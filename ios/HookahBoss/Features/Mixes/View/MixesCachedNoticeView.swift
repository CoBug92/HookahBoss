import SwiftUI

struct MixesCachedNoticeView: View {

    // MARK: - Properties

    let onRetry: () -> Void

    // MARK: - Layout

    var body: some View {
        HStack(
            alignment: .top,
            spacing: Margin.x5
        ) {
            Image(systemName: AppSymbol.retryUnavailable)
                .font(.headline)
                .foregroundStyle(AppTheme.gold)
                .frame(
                    width: .iconSize,
                    height: .iconSize
                )
                .background(
                    AppTheme.gold.opacity(.iconBackgroundOpacity),
                    in: Circle()
                )

            VStack(alignment: .leading, spacing: Margin.x2) {
                Text(L10n.Mixes.Cached.title)
                    .font(.subheadline.bold())

                Text(L10n.Mixes.Cached.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            Spacer(minLength: Margin.x2)

            Button(action: onRetry) {
                Image(systemName: AppSymbol.sync)
                    .font(.headline)
                    .foregroundStyle(AppTheme.gold)
                    .frame(
                        width: .actionSize,
                        height: .actionSize
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.Common.retry))
        }
        .padding(Margin.x6)
        .appCard(cornerRadius: .cornerRadius)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let iconSize: CGFloat = 38
    static let actionSize: CGFloat = 44
    static let cornerRadius: CGFloat = 20
}

private extension Double {
    static let iconBackgroundOpacity: Double = 0.12
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    MixesCachedNoticeView(onRetry: {})
        .padding(Margin.x8)
        .background(AppTheme.background)
}
