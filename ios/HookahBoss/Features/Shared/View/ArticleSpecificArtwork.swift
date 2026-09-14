import SwiftUI

struct ArticleSpecificArtwork: View {
    let article: ArticleDTO

    var body: some View {
        Image(ArticleArtworkResource.resource(for: article))
            .resizable()
            .scaledToFill()
            .clipped()
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    ArticleSpecificArtwork(
        article: ArticleDTO(
            id: UUID(),
            slug: "building-a-mix",
            title: "Build a mix with a story",
            summary: "A practical guide",
            category: "preparation",
            readingMinutes: 7
        )
    )
        .frame(width: 320, height: 200)
}
