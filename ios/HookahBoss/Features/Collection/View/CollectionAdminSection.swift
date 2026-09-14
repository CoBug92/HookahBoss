import SwiftUI

struct CollectionAdminSection: View {
    let onOpen: () -> Void

    var body: some View {
        Section(L10n.Admin.serviceSection) {
            Button(action: onOpen) {
                HStack(spacing: Margin.x6) {
                    Image(systemName: AppSymbol.tools)
                        .foregroundStyle(AppTheme.gold)
                        .frame(width: .iconWidth)

                    VStack(alignment: .leading, spacing: Margin.x2) {
                        Text(L10n.Admin.title)
                            .font(.body.weight(.medium))

                        Text(L10n.Admin.serviceHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: AppSymbol.disclosure)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("admin.entry")
            .accessibilityHint(Text(L10n.Admin.serviceHint))
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let iconWidth: CGFloat = 28
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    List {
        CollectionAdminSection(onOpen: {})
    }
}
