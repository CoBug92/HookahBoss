import SwiftUI

struct ArticlesView: View {
    @StateObject private var content = PublicContentStore()
    @EnvironmentObject private var auth:AuthRuntime
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    Text("articles.subtitle").font(.subheadline).foregroundStyle(.secondary)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(ArticleCategory.allCases) { category in
                            NavigationLink(value: category) { CategoryCard(category: category, count: content.articles.filter { $0.appCategory == category }.count) }.buttonStyle(.plain)
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("articles.recommended").font(.title2.bold())
                        ForEach(content.articles.prefix(5)) { ArticleRow(article: $0, auth: auth) }
                    }
                }.padding(18)
            }
            .overlay { if content.articles.isEmpty { stateOverlay } }
            .refreshable { await content.load(locale: .currentApp, force: true) }
            .task { await content.load(locale: .currentApp) }
            .navigationTitle("tab.articles")
            .toolbar { NavigationLink(value: ArticleDestination.bookmarks) { Image(systemName: "bookmark") }.accessibilityLabel(Text("articles.bookmarks")) }
            .navigationDestination(for: ArticleCategory.self) { category in ArticleListView(title: category.titleKey, articles: content.articles.filter { $0.appCategory == category }, auth: auth) }
            .navigationDestination(for: ArticleDestination.self) { _ in ArticleListView(title: "articles.bookmarks", articles: content.articles.filter { auth.bookmarkedArticleSlugs.contains($0.slug) }, auth: auth, emptyBookmarks: true) }
            .navigationDestination(for: ArticleDTO.self) { ArticleReaderView(article: $0, content: content, auth: auth) }
            .background(AppTheme.background)
            .accessibilityIdentifier("screen.articles")
        }
    }

    @ViewBuilder private var stateOverlay: some View {
        switch content.state {
        case .idle, .loading: ProgressView()
        case .failed(let message): ContentUnavailableView("content.error.title", systemImage: "wifi.exclamationmark", description: Text(message))
        case .loaded: ContentUnavailableView("content.empty.articles", systemImage: "book.closed")
        }
    }
}

private enum ArticleDestination: Hashable { case bookmarks }
private struct CategoryCard: View {
    let category: ArticleCategory; let count: Int
    var body: some View { VStack(alignment: .leading, spacing: 16) { Image(systemName: category.icon).font(.title2).foregroundStyle(AppTheme.gold); Text(LocalizedStringKey(category.titleKey)).font(.headline); Text("articles.count \(count)").font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, minHeight: 112, alignment: .leading).padding(16).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 20)) }
}
private struct ArticleListView: View {
    let title: String; let articles: [ArticleDTO]; @ObservedObject var auth: AuthRuntime; var emptyBookmarks = false
    var body: some View { Group { if articles.isEmpty { ContentUnavailableView(emptyBookmarks ? "articles.bookmarks.empty" : "articles.empty", systemImage: "bookmark.slash") } else { List(articles) { ArticleRow(article: $0, auth: auth).listRowBackground(AppTheme.card) }.listStyle(.plain) } }.navigationTitle(LocalizedStringKey(title)).appScreenBackground() }
}
private struct ArticleRow: View {
    let article: ArticleDTO; @ObservedObject var auth: AuthRuntime
    var body: some View {
        NavigationLink(value: article) {
            HStack(spacing: 12) {
                Image(systemName: article.appCategory.icon).foregroundStyle(AppTheme.gold).frame(width: 38, height: 38).background(AppTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 4) { Text(article.title).font(.headline).lineLimit(2); Text("articles.minutes \(article.readingMinutes)").font(.caption).foregroundStyle(.secondary) }
                Spacer()
                Button { toggleBookmark() } label: { Image(systemName: auth.bookmarkedArticleSlugs.contains(article.slug) ? "bookmark.fill" : "bookmark") }.buttonStyle(.borderless).frame(minWidth:44,minHeight:44).accessibilityLabel(Text(auth.bookmarkedArticleSlugs.contains(article.slug) ? "bookmark.remove":"bookmark.add")).accessibilityValue(Text(auth.bookmarkedArticleSlugs.contains(article.slug) ? "accessibility.selected":"accessibility.notSelected"))
            }
        }.accessibilityIdentifier("article.row.\(article.slug)")
    }
    private func toggleBookmark(){let action:()->Void = {Task{await auth.setArticleBookmark(!auth.bookmarkedArticleSlugs.contains(article.slug),slug:article.slug)}};if auth.isAuthenticated{action()}else{auth.gate.request(.bookmark,resume:action)}}
}
private struct ArticleReaderView: View {
    let article: ArticleDTO; @ObservedObject var content: PublicContentStore; @ObservedObject var auth: AuthRuntime
    @State private var detail: ArticleDetailDTO?; @State private var failed = false
    var body: some View { ScrollView { VStack(spacing: 0) { hero; if let detail { bodyView(detail) } else if failed { ContentUnavailableView("content.error.title", systemImage: "wifi.exclamationmark").padding() } else { ProgressView().padding(40) } } }.background(AppTheme.background).ignoresSafeArea(edges: .top).toolbar { Button { toggleBookmark() } label: { Image(systemName: auth.bookmarkedArticleSlugs.contains(article.slug) ? "bookmark.fill" : "bookmark") }.accessibilityLabel(Text(auth.bookmarkedArticleSlugs.contains(article.slug) ? "bookmark.remove":"bookmark.add")).accessibilityValue(Text(auth.bookmarkedArticleSlugs.contains(article.slug) ? "accessibility.selected":"accessibility.notSelected")) }.task { do { detail = try await content.articleDetail(article.slug, locale: .currentApp) } catch { failed = true } }.accessibilityIdentifier("screen.articleReader") }
    private func bodyView(_ detail: ArticleDetailDTO) -> some View {
        VStack(alignment: .leading, spacing: 26) {
            Text(detail.summary).font(.title3).foregroundStyle(.secondary)
            ForEach(Array(detail.sections.enumerated()), id: \.offset) { _, section in
                VStack(alignment: .leading, spacing: 10) { Text(section.heading).font(.title2.bold()); Text(section.body).lineSpacing(6) }
            }
            if !detail.related.isEmpty {
                Divider(); Text("articles.related").font(.title2.bold())
                ForEach(detail.related) { related in
                    NavigationLink(value: related) { RelatedArticleCard(article: related) }.buttonStyle(.plain)
                }
            }
        }.padding(20)
    }
    private func toggleBookmark(){let action:()->Void = {Task{await auth.setArticleBookmark(!auth.bookmarkedArticleSlugs.contains(article.slug),slug:article.slug)}};if auth.isAuthenticated{action()}else{auth.gate.request(.bookmark,resume:action)}}
    private var hero: some View { ZStack(alignment: .bottomLeading) { if let image=ArtworkResource.image(named:article.appCategory.artworkFilename){Image(uiImage:image).resizable().scaledToFill()}else{LinearGradient(colors: [AppTheme.gold.opacity(0.8), AppTheme.cardDark, AppTheme.graphite], startPoint: .topLeading, endPoint: .bottomTrailing);Image(systemName: article.appCategory.icon).font(.system(size: 150, weight: .thin)).foregroundStyle(.white.opacity(0.16)).offset(x: 175, y: -42)}; LinearGradient(colors: [.clear, .black.opacity(0.94)], startPoint: .top, endPoint: .bottom); VStack(alignment: .leading, spacing: 10) { Label(LocalizedStringKey(article.appCategory.titleKey), systemImage: article.appCategory.icon).font(.caption.bold()).foregroundStyle(AppTheme.cream); Text(article.title).font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(.white); Label("articles.minutes \(article.readingMinutes)", systemImage: "clock").font(.subheadline).foregroundStyle(.white.opacity(0.8)) }.padding(20) }.frame(height: 390).clipped() }
}
private struct RelatedArticleCard: View { let article: ArticleDTO; var body: some View { HStack(spacing: 14) { Image(systemName: article.appCategory.icon).foregroundStyle(AppTheme.gold).frame(width: 48, height: 48).background(AppTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14)); VStack(alignment: .leading) { Text(article.title).font(.headline).lineLimit(2); Text("articles.minutes \(article.readingMinutes)").font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary) }.padding(14).background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18)) } }
private extension ArticleDTO { var appCategory: ArticleCategory { switch category { case "fundamentals": .basics; case "bowls_heat": .heat; default: ArticleCategory(rawValue: category) ?? .basics } } }
