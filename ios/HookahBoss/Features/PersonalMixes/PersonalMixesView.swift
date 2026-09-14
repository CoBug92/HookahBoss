import SwiftUI

struct PersonalMixesView: View {
    let mixes: [PersonalMixRecord]

    var body: some View {
        Group {
            if mixes.isEmpty {
                ContentUnavailableView(
                    L10n.Collection.Personal.Empty.title,
                    systemImage: AppSymbol.collection,
                    description: Text(L10n.Collection.Personal.Empty.message)
                )
            } else {
                List(mixes) { mix in
                    NavigationLink {
                        PersonalMixDetailView(
                            model: PersonalMixDetailViewModel(mix: mix)
                        )
                    } label: {
                        PersonalMixRow(mix: mix)
                    }
                    .listRowBackground(AppTheme.card)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle(L10n.Collection.personalMixes)
        .appScreenBackground()
    }
}

// MARK: - Preview

#Preview("Content") {
    NavigationStack {
        PersonalMixesView(mixes: PersonalMixPreviewData.collection)
    }
}

#Preview("Empty") {
    NavigationStack {
        PersonalMixesView(mixes: [])
    }
}
