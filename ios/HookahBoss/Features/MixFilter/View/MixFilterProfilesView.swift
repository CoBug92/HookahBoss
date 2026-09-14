import SwiftUI

struct MixFilterProfilesView: View {
    let selectedProfiles: Set<FlavorProfile>
    let onToggle: (FlavorProfile) -> Void

    var body: some View {
        MixFilterSection(
            title: L10n.Filters.profiles,
            subtitle: L10n.Filters.multiple
        ) {
            FilterFlowLayout(spacing: Margin.x4) {
                ForEach(FlavorProfile.allCases) { profile in
                    MixFilterChip(
                        title: profile.title,
                        isSelected: selectedProfiles.contains(profile),
                        action: { onToggle(profile) }
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    MixFilterProfilesView(
        selectedProfiles: [.citrus, .fresh],
        onToggle: { _ in }
    )
    .padding(Margin.x8)
}
