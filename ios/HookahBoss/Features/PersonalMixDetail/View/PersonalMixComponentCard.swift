import SwiftUI

struct PersonalMixComponentCard: View {
    let component: PersonalMixComponentViewData

    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x4) {
            Text(component.flavor)
                .font(.headline)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            if let brandAndLine = component.brandAndLine {
                Text(brandAndLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: Margin.x2)

            Text(
                component.percentage.map { "\($0)%" }
                    ?? TechnicalString.emDash
            )
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.gold)
        }
        .padding(Margin.x7)
        .frame(
            width: .width,
            height: .height,
            alignment: .leading
        )
        .background(
            AppTheme.card,
            in: RoundedRectangle(
                cornerRadius: .cornerRadius,
                style: .continuous
            )
        )
    }
}

// MARK: - Constants

private extension CGFloat {
    static let width: CGFloat = 148
    static let height: CGFloat = 154
    static let cornerRadius: CGFloat = 18
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    PersonalMixComponentCard(
        component: PersonalMixComponentViewData(
            id: UUID(),
            flavor: "Mango",
            brandAndLine: "DARKSIDE · Core",
            percentage: 60
        )
    )
    .padding(Margin.x8)
    .background(AppTheme.background)
}
