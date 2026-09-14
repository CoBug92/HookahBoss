import SwiftUI

struct HomeCachedContentView: View {

    // MARK: - Properties

    let mixOfDay: MixPreview?
    let recommendations: [MixPreview]
    let onFindMix: () -> Void
    let onInventory: () -> Void
    let onRetry: () -> Void

    // MARK: - Layout

    var body: some View {
        LazyVStack(
            alignment: .leading,
            spacing: Margin.x6
        ) {
            notice
            HomeLoadedContentView(
                mixOfDay: mixOfDay,
                recommendations: recommendations,
                onFindMix: onFindMix,
                onInventory: onInventory
            )
        }
    }

    private var notice: some View {
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
                Text(L10n.Home.Cached.title)
                    .font(.subheadline.bold())

                Text(L10n.Home.Cached.message)
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

#Preview {
    NavigationStack {
        ScrollView {
            HomeCachedContentView(
                mixOfDay: HomePreviewData.mixOfDay,
                recommendations: HomePreviewData.recommendations,
                onFindMix: {},
                onInventory: {},
                onRetry: {}
            )
            .padding(Margin.x9)
        }
        .background(AppTheme.background)
    }
}
