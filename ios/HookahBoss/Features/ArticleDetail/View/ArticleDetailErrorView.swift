import SwiftUI

struct ArticleDetailErrorView: View {
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(
                L10n.Articles.Error.title,
                systemImage: AppSymbol.retryUnavailable
            )
        } description: {
            Text(L10n.Articles.Error.message)
        } actions: {
            Button(L10n.Common.retry, action: retry)
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.gold)
        }
        .padding(Margin.x8)
    }
}

// MARK: - Preview

#Preview {
    ArticleDetailErrorView(retry: {})
        .background(AppTheme.background)
}
