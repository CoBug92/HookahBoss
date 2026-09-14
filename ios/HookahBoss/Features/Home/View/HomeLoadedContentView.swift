import SwiftUI

struct HomeLoadedContentView: View {
    let mixOfDay: MixPreview?
    let recommendations: [MixPreview]
    let onFindMix: () -> Void
    let onInventory: () -> Void

    var body: some View {
        LazyVStack(
            alignment: .leading,
            spacing: Margin.x(12)
        ) {
            if let mixOfDay {
                HomeMixOfDayView(mix: mixOfDay)
            }
            HomeQuickActionsView(
                onFindMix: onFindMix,
                onInventory: onInventory
            )
            HomeRecommendationsView(mixes: recommendations)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView {
            HomeLoadedContentView(
                mixOfDay: HomePreviewData.mixOfDay,
                recommendations: HomePreviewData.recommendations,
                onFindMix: {},
                onInventory: {}
            )
            .padding(Margin.x9)
        }
        .background(AppTheme.background)
    }
}
