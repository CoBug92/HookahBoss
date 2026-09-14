import SwiftUI

struct MixFilterExclusionsView: View {
    @Binding var excludedFlavor: String

    var body: some View {
        MixFilterSection(
            title: L10n.Filters.exclude,
            subtitle: L10n.Filters.excludeHint
        ) {
            HStack(spacing: Margin.x5) {
                Image(systemName: AppSymbol.remove)
                    .foregroundStyle(.secondary)
                TextField(
                    L10n.Filters.excludePlaceholder,
                    text: $excludedFlavor
                )
                .textInputAutocapitalization(.never)
            }
            .padding(Margin.x7)
            .background(AppTheme.card)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: .textFieldCornerRadius,
                    style: .continuous
                )
            )
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let textFieldCornerRadius: CGFloat = 15
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    @Previewable @State var excludedFlavor = "Anise"

    MixFilterExclusionsView(excludedFlavor: $excludedFlavor)
        .padding(Margin.x8)
}
