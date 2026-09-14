import SwiftUI

struct ArticleArtwork: View {
    let category: ArticleCategory

    var body: some View {
        Image(ArticleArtworkResource.resource(for: category))
            .resizable()
            .scaledToFill()
            .clipped()
            .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let previewWidth: CGFloat = 320
    static let previewHeight: CGFloat = 200
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    ArticleArtwork(category: .basics)
        .frame(width: .previewWidth, height: .previewHeight)
}
