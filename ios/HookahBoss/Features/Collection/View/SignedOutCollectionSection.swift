import SwiftUI

struct SignedOutCollectionSection: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Section(title) {
            Button(action: action) {
                HStack(spacing: Margin.x4) {
                    RoundedRectangle(cornerRadius: .artworkCornerRadius)
                        .fill(.secondary.opacity(.artworkOpacity))
                        .frame(width: .artworkSize, height: .artworkSize)

                    VStack(
                        alignment: .leading,
                        spacing: Margin.x4
                    ) {
                        RoundedRectangle(cornerRadius: .lineCornerRadius)
                            .fill(.secondary.opacity(.titleOpacity))
                            .frame(height: .titleHeight)

                        RoundedRectangle(cornerRadius: .lineCornerRadius)
                            .fill(.secondary.opacity(.subtitleOpacity))
                            .frame(
                                width: .subtitleWidth,
                                height: .subtitleHeight
                            )
                    }
                }
                .redacted(reason: .placeholder)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let artworkSize: CGFloat = 42
    static let artworkCornerRadius: CGFloat = 8
    static let lineCornerRadius: CGFloat = 4
    static let titleHeight: CGFloat = 12
    static let subtitleWidth: CGFloat = 120
    static let subtitleHeight: CGFloat = 10
}

private extension Double {
    static let artworkOpacity: Double = 0.12
    static let titleOpacity: Double = 0.16
    static let subtitleOpacity: Double = 0.1
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    List {
        SignedOutCollectionSection(
            title: L10n.Collection.personalMixes,
            action: {}
        )
    }
}
