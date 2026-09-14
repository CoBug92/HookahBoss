import SwiftUI

struct HomeQuickActionView: View {
    let title: String
    let icon: String
    let emphasized: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Margin.x6) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: .iconSize, height: .iconSize)
                    .background(
                        emphasized ? Color.white.opacity(.emphasizedIconOpacity) : AppTheme.gold.opacity(.iconOpacity),
                        in: RoundedRectangle(cornerRadius: .iconCornerRadius)
                    )
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: .minimumHeight, alignment: .leading)
            .padding(Margin.x8)
            .foregroundStyle(emphasized ? Color.white : Color.primary)
            .background(emphasized ? AppTheme.gold : AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadius)
                    .stroke(emphasized ? .clear : Color.primary.opacity(.borderOpacity))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let iconSize: CGFloat = 34
    static let iconCornerRadius: CGFloat = 10
    static let minimumHeight: CGFloat = 82
    static let cornerRadius: CGFloat = 18
}

private extension Double {
    static let emphasizedIconOpacity: Double = 0.14
    static let iconOpacity: Double = 0.12
    static let borderOpacity: Double = 0.07
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    HomeQuickActionView(
        title: L10n.Home.findMix,
        icon: AppSymbol.filters,
        emphasized: true,
        action: {}
    )
    .frame(width: 180)
    .padding(Margin.x5)
}
