import SwiftUI

struct MixGridView: View {
    let mixes: [MixPreview]
    var accessibilityIdentifierPrefix: String?

    var body: some View {
        LazyVGrid(columns: columns, spacing: Margin.x6) {
            ForEach(mixes) { mix in
                mixLink(for: mix)
            }
        }
    }

    @ViewBuilder
    private func mixLink(for mix: MixPreview) -> some View {
        let link = NavigationLink(value: mix) {
            MixCardView(mix: mix)
        }
        .buttonStyle(.plain)

        if let accessibilityIdentifierPrefix {
            link.accessibilityIdentifier(
                "\(accessibilityIdentifierPrefix).\(mix.id.uuidString)"
            )
        } else {
            link
        }
    }
}

// MARK: - Constants

private extension MixGridView {
    var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Margin.x6),
            GridItem(.flexible(), spacing: Margin.x6),
        ]
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    NavigationStack {
        MixGridView(mixes: MixesPreviewData.catalog)
            .padding(Margin.x8)
    }
}
