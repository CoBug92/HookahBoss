import SwiftUI

struct MixFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, Margin.x7)
                .padding(.vertical, Margin.x5)
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
                .background(isSelected ? AppTheme.gold : AppTheme.card)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(
                            isSelected ? .clear : Color.primary.opacity(.chipBorderOpacity),
                            lineWidth: .borderWidth
                        )
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let borderWidth: CGFloat = 1
}

private extension Double {
    static let chipBorderOpacity: Double = 0.08
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    HStack {
        MixFilterChip(
            title: "Citrus",
            isSelected: true,
            action: {}
        )
        MixFilterChip(
            title: "Berry",
            isSelected: false,
            action: {}
        )
    }
    .padding(Margin.x5)
}
