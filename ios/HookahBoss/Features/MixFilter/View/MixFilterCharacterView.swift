import SwiftUI

struct MixFilterCharacterView: View {
    @Binding var sweetness: FlavorIntensity
    @Binding var acidity: FlavorIntensity
    @Binding var freshness: FlavorIntensity

    var body: some View {
        MixFilterSection(title: L10n.Filters.character) {
            VStack(spacing: Margin.x6) {
                MixIntensityPicker(
                    title: L10n.Filters.sweetness,
                    selection: $sweetness
                )
                MixIntensityPicker(
                    title: L10n.Filters.acidity,
                    selection: $acidity
                )
                MixIntensityPicker(
                    title: L10n.Filters.freshness,
                    selection: $freshness
                )
            }
        }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    @Previewable @State var sweetness = FlavorIntensity.subtle
    @Previewable @State var acidity = FlavorIntensity.pronounced
    @Previewable @State var freshness = FlavorIntensity.any

    MixFilterCharacterView(
        sweetness: $sweetness,
        acidity: $acidity,
        freshness: $freshness
    )
    .padding(Margin.x8)
}
