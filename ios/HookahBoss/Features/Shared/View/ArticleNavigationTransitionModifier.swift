import SwiftUI

struct ArticleNavigationTransitionModifier: ViewModifier {
    @Environment(\.articleTransitionNamespace) private var namespace
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
    func articleNavigationTransition(sourceID: UUID) -> some View {
        modifier(ArticleNavigationTransitionModifier(sourceID: sourceID))
    }
}
