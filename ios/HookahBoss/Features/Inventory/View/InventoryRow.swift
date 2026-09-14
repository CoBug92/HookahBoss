import SwiftUI

struct InventoryRow: View {
    let item: InventoryItem
    let isExpanded: Bool
    let toggle: () -> Void
    let select: (InventoryLevel) -> Void

    var body: some View {
        VStack(spacing: Margin.x6) {
            summaryButton
            if isExpanded {
                levelPicker
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, Margin.x2)
    }

    private var summaryButton: some View {
        Button(action: toggle) {
            HStack(spacing: Margin.x6) {
                VStack(alignment: .leading, spacing: Margin.x2) {
                    Text(item.flavor)
                        .font(.headline)
                    Text(item.brandAndLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(item.level.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(item.level.color)
                Image(systemName: AppSymbol.expand)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? .expandedRotation : .zero))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(item.flavor), \(item.brandAndLine)"))
        .accessibilityValue(Text(item.level.title))
        .accessibilityHint(
            Text(isExpanded ? L10n.Inventory.Accessibility.collapse : L10n.Inventory.Accessibility.expand)
        )
    }

    private var levelPicker: some View {
        HStack(spacing: Margin.x4) {
            ForEach(InventoryLevel.allCases) { level in
                Button {
                    select(level)
                } label: {
                    Text(level.title)
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Margin.x5)
                        .foregroundStyle(item.level == level ? Color.white : level.color)
                        .background(
                            item.level == level ? level.color : level.color.opacity(.unselectedLevelOpacity),
                            in: RoundedRectangle(cornerRadius: .levelCornerRadius)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(level.title))
                .accessibilityValue(
                    Text(item.level == level ? L10n.Accessibility.selected : L10n.Accessibility.notSelected)
                )
            }
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let levelCornerRadius: CGFloat = 12
}

private extension Double {
    static let expandedRotation = 180.0
    static let unselectedLevelOpacity = 0.11
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    InventoryRow(
        item: InventoryItem(
            id: "preview",
            brand: "DARKSIDE",
            line: "Core",
            flavor: "Mango",
            level: .plenty,
            flavorProfiles: ["fruit"]
        ),
        isExpanded: true,
        toggle: {},
        select: { _ in }
    )
    .padding(Margin.x8)
}
