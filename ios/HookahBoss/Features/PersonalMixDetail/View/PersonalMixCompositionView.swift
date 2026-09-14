import SwiftUI

struct PersonalMixCompositionView: View {
    let components: [PersonalMixComponentViewData]

    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x6) {
            Text(L10n.Mix.composition)
                .font(.title2.weight(.semibold))

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Margin.x5) {
                    ForEach(components) { component in
                        PersonalMixComponentCard(component: component)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier(AccessibilityID.personalMixComposition)
        }
        .padding(.horizontal, Margin.x10)
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    PersonalMixCompositionView(
        components: [
            PersonalMixComponentViewData(
                id: UUID(),
                flavor: "Mango",
                brandAndLine: "DARKSIDE · Core",
                percentage: 60
            ),
        ]
    )
    .background(AppTheme.background)
}
