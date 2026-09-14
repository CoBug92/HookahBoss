import SwiftUI

struct CollectionPersonalMixesSection: View {
    let mixes: [PersonalMixRecord]

    var body: some View {
        if !mixes.isEmpty {
            Section(L10n.Collection.personalMixes) {
                ForEach(mixes) { mix in
                    NavigationLink {
                        PersonalMixDetailView(
                            model: PersonalMixDetailViewModel(mix: mix)
                        )
                    } label: {
                        PersonalMixRow(mix: mix)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    List {
        CollectionPersonalMixesSection(
            mixes: CollectionPreviewData.personalMixes
        )
    }
}
