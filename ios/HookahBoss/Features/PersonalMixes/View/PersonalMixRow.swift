import SwiftUI

struct PersonalMixRow: View {
    let mix: PersonalMixRecord

    var body: some View {
        HStack(spacing: Margin.x6) {
            PersonalMixArtwork(mix: mix)
                .frame(width: .artworkSize, height: .artworkSize)
            VStack(alignment: .leading, spacing: Margin.x3) {
                Text(mix.title ?? L10n.Collection.untitledMix)
                    .font(.headline)
                Text(L10n.Collection.componentsLld(mix.components.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if mix.isApproximate == true {
                    Text(L10n.PersonalMix.approximate)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let artworkSize: CGFloat = 52
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    PersonalMixRow(
        mix: PersonalMixRecord(
            id: UUID(),
            title: "Tropical Mix",
            components: [],
            createdAt: .now,
            isApproximate: true
        )
    )
    .padding(Margin.x8)
}
