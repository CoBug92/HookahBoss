import SwiftUI

struct MixFilterStrengthView: View {
    let selection: MixStrength?
    let onToggle: (MixStrength) -> Void

    var body: some View {
        MixFilterSection(title: L10n.Filters.strength) {
            HStack(spacing: Margin.x4) {
                ForEach(MixStrength.filterOptions, id: \.self) { option in
                    MixFilterChip(
                        title: option.title,
                        isSelected: selection == option,
                        action: { onToggle(option) }
                    )
                }
            }
        }
    }
}

// MARK: - Constants

private extension MixStrength {
    static let filterOptions: [MixStrength] = [.light, .medium, .strong]
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    MixFilterStrengthView(
        selection: .medium,
        onToggle: { _ in }
    )
    .padding(Margin.x8)
}
