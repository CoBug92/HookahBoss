import SwiftUI

struct MixRatingSheet: View {
    @Binding var selection: Int?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Margin.x9) {
            VStack(spacing: Margin.x3) {
                Text(L10n.Rating.title)
                    .font(.title2.weight(.semibold))
                Text(L10n.Rating.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: Margin.x5) {
                ForEach(1...5, id: \.self) { score in
                    Button {
                        selection = score
                        dismiss()
                    } label: {
                        Image(systemName: AppSymbol.ratingFilled)
                            .font(.title3)
                            .foregroundStyle(
                                selection == score
                                    ? AppTheme.ratingColor(for: score)
                                    : Color.secondary
                            )
                            .frame(
                                width: .ratingButtonSize,
                                height: .ratingButtonSize
                            )
                            .background(AppTheme.card)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: .ratingButtonCornerRadius,
                                    style: .continuous
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("\(score)"))
                    .accessibilityValue(
                        Text(
                            selection == score
                                ? L10n.Accessibility.selected
                                : L10n.Accessibility.notSelected
                        )
                    )
                }
            }
        }
        .padding(Margin.x(12))
    }
}

// MARK: - Constants

private extension CGFloat {
    static let ratingButtonSize: CGFloat = 46
    static let ratingButtonCornerRadius: CGFloat = 14
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    @Previewable @State var selection: Int? = 4

    MixRatingSheet(selection: $selection)
}
