import SwiftUI

struct MixIntensityPicker: View {
    let title: String
    @Binding var selection: FlavorIntensity

    var body: some View {
        HStack(spacing: Margin.x5) {
            Text(title)
                .font(.subheadline)
                .frame(
                    width: .intensityTitleWidth,
                    alignment: .leading
                )

            Picker(title, selection: $selection) {
                ForEach(FlavorIntensity.allCases) { option in
                    Text(option.title)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let intensityTitleWidth: CGFloat = 84
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    @Previewable @State var selection = FlavorIntensity.subtle

    MixIntensityPicker(
        title: L10n.Filters.sweetness,
        selection: $selection
    )
    .padding(Margin.x5)
}
