import SwiftUI

struct FlavorCloud: View {
    let tags: [String]

    var body: some View {
        FlavorFlowLayout(spacing: Margin.x2) {
            ForEach(tags.prefix(3), id: \.self) { tag in
                Text(tag)
                    .font(
                        .system(
                            size: .flavorTagFontSize,
                            weight: .medium
                        )
                    )
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, Margin.x4)
                    .padding(.vertical, Margin.x2)
                    .background(
                        .white.opacity(.flavorBackgroundOpacity),
                        in: Capsule()
                    )
                    .overlay {
                        Capsule()
                            .stroke(
                                .white.opacity(.flavorBorderOpacity),
                                lineWidth: .flavorBorderWidth
                            )
                    }
            }
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let flavorTagFontSize: CGFloat = 9
    static let flavorBorderWidth: CGFloat = 0.8
}

private extension Double {
    static let flavorBackgroundOpacity: Double = 0.12
    static let flavorBorderOpacity: Double = 0.25
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    FlavorCloud(tags: ["Lemon", "Mint", "Berry"])
        .padding(Margin.x5)
        .background(Color.black)
}
