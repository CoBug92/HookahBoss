import SwiftUI

struct MixFilterSection<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x6) {
            VStack(alignment: .leading, spacing: Margin.x2) {
                Text(title)
                    .font(.title3.weight(.bold))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            content
        }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    MixFilterSection(
        title: L10n.Filters.profiles,
        subtitle: L10n.Filters.multiple
    ) {
        Text("Citrus")
    }
    .padding(Margin.x8)
}
