import SwiftUI

struct MixNavigationTransitionModifier: ViewModifier {
    @Environment(\.mixTransitionNamespace) private var namespace
    let sourceID: UUID

    @ViewBuilder
    func body(content: Content) -> some View {
        if let namespace {
            content.navigationTransition(
                .zoom(
                    sourceID: sourceID,
                    in: namespace
                )
            )
        } else {
            content
        }
    }
}

extension View {
    func mixNavigationTransition(sourceID: UUID) -> some View {
        modifier(MixNavigationTransitionModifier(sourceID: sourceID))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        Text(MixesPreviewData.featured.title)
            .mixNavigationTransition(sourceID: MixesPreviewData.featured.id)
    }
}
