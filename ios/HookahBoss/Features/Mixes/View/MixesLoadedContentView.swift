import SwiftUI

struct MixesLoadedContentView: View {

    // MARK: - Properties

    let mixes: [MixPreview]

    // MARK: - Layout

    var body: some View {
        if mixes.isEmpty {
            AppEmptyState(
                icon: AppSymbol.search,
                title: L10n.Mixes.Search.Empty.title,
                message: L10n.Mixes.Search.Empty.message
            )
        } else {
            MixGridView(
                mixes: mixes,
                accessibilityIdentifierPrefix: AccessibilityID.mixCardPrefix
            )
        }
    }
}

// MARK: - Preview

#Preview("Content", traits: .sizeThatFitsLayout) {
    NavigationStack {
        MixesLoadedContentView(mixes: MixesPreviewData.catalog)
            .padding(Margin.x8)
            .background(AppTheme.background)
    }
}

#Preview("No search results", traits: .sizeThatFitsLayout) {
    MixesLoadedContentView(mixes: [])
        .padding(Margin.x8)
        .background(AppTheme.background)
}
