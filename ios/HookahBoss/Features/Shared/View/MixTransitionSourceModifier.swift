import SwiftUI

struct MixTransitionSourceModifier: ViewModifier {
    @Environment(\.mixTransitionNamespace) private var namespace
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
    func mixTransitionSource(id: UUID) -> some View {
        modifier(MixTransitionSourceModifier(sourceID: id))
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    MixCardView(mix: MixesPreviewData.featured)
        .frame(width: 180)
        .padding(Margin.x5)
}
