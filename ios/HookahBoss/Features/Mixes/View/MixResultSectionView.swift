import SwiftUI

struct MixResultSectionView: View {
    let title: String
    let mixes: [MixPreview]

    var body: some View {
        if !mixes.isEmpty {
            VStack(alignment: .leading, spacing: Margin.x6) {
                AppSectionHeader(title: title)
                MixGridView(mixes: mixes)
            }
        }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    NavigationStack {
        MixResultSectionView(
            title: L10n.Results.ideal,
            mixes: MixesPreviewData.catalog
        )
        .padding(Margin.x8)
    }
}
