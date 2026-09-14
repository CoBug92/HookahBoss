import SwiftUI

struct ArticleTransitionSourceModifier: ViewModifier {
    @Environment(\.articleTransitionNamespace) private var namespace
    let sourceID: UUID

    @ViewBuilder
    func body(content: Content) -> some View {
        if let namespace {
            content.matchedTransitionSource(
                id: sourceID,
                in: namespace
            )
        } else {
            content
        }
    }
}

extension View {
    func articleTransitionSource(id: UUID) -> some View {
        modifier(ArticleTransitionSourceModifier(sourceID: id))
    }
}
