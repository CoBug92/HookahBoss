import SwiftUI

struct ArticlesView: View {
    @StateObject private var model: ArticlesViewModel
    let makeDetailModel: (ArticleDTO) -> ArticleDetailViewModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    init(model: @autoclosure @escaping () -> ArticlesViewModel,
         makeDetailModel: @escaping (ArticleDTO) -> ArticleDetailViewModel) {
        _model = StateObject(wrappedValue: model())
        self.makeDetailModel = makeDetailModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    Text(L10n.Articles.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(ArticleCategory.allCases) { category in
                            NavigationLink(value: category) { CategoryCard(category: category, count: model.articles(in: category).count) }
                                .buttonStyle(.plain)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text(L10n.Articles.recommended).font(.title2.bold())
                        ForEach(Array(model.articles.prefix(5))) { article in
                            ArticleRow(article: article, bookmarked: model.isBookmarked(article), toggle: { model.toggleBookmark(article) })
                        }
                    }
                }.padding(18)
            }
            .overlay { if model.isLoading && model.articles.isEmpty { ProgressView() } }
            .refreshable { await model.refresh() }.task { await model.appear() }
            .navigationTitle(L10n.Tab.articles)
            .toolbar { NavigationLink(value: ArticleDestination.bookmarks) { Image(systemName: "bookmark") }.accessibilityLabel(Text(L10n.Articles.bookmarks)) }
            .navigationDestination(for: ArticleCategory.self) { category in ArticleListView(content: .category(category), model: model) }
            .navigationDestination(for: ArticleDestination.self) { _ in ArticleListView(content: .bookmarks, model: model) }
            .navigationDestination(for: ArticleDTO.self) { article in ArticleReaderView(article: article, model: makeDetailModel(article)) }
            .onAppear { model.syncLibraryState() }
            .alert(L10n.Content.Error.title,isPresented:Binding(get:{model.errorMessage != nil},set:{if !$0{model.clearError()}})){Button(L10n.Common.close){model.clearError()}}message:{Text(model.errorMessage ?? "")}
            .background(AppTheme.background).accessibilityIdentifier("screen.articles")
        }
    }
}

private enum ArticleDestination: Hashable { case bookmarks }

private struct CategoryCard: View {
    let category: ArticleCategory; let count: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: category.icon).font(.title2).foregroundStyle(AppTheme.gold)
            Text(category.title).font(.headline)
            Text(L10n.Articles.countLld(count)).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, minHeight: 112, alignment: .leading).padding(16).background(AppTheme.card).clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct ArticleListView: View {
    enum Content { case category(ArticleCategory),bookmarks }
    let content: Content; @ObservedObject var model: ArticlesViewModel
    private var articles:[ArticleDTO]{switch content{case .category(let category):model.articles(in:category);case .bookmarks:model.bookmarks}}
    private var title:String{switch content{case .category(let category):category.title;case .bookmarks:L10n.Articles.bookmarks}}
    private var emptyBookmarks:Bool{if case .bookmarks=content{return true};return false}
    var body: some View {
        Group {
            if articles.isEmpty { ContentUnavailableView(emptyBookmarks ? L10n.Articles.Bookmarks.empty:L10n.Articles.empty, systemImage: "bookmark.slash") }
            else { List(articles) { article in ArticleRow(article: article, bookmarked: model.isBookmarked(article), toggle: { model.toggleBookmark(article) }).listRowBackground(AppTheme.card) }.listStyle(.plain) }
        }.navigationTitle(title).appScreenBackground()
    }
}

private struct ArticleRow: View {
    let article: ArticleDTO; let bookmarked: Bool; let toggle: () -> Void
    var body: some View {
        NavigationLink(value: article) {
            HStack(spacing: 12) {
                Image(systemName: article.appCategory.icon).foregroundStyle(AppTheme.gold).frame(width: 38, height: 38).background(AppTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading) { Text(article.title).font(.headline).lineLimit(2); Text(L10n.Articles.minutesLld(article.readingMinutes)).font(.caption).foregroundStyle(.secondary) }
                Spacer()
                Button(action: toggle) { Image(systemName: bookmarked ? "bookmark.fill":"bookmark") }.buttonStyle(.borderless)
                    .accessibilityLabel(Text(L10n.Articles.bookmarks)).accessibilityValue(Text(bookmarked ? L10n.Accessibility.selected:L10n.Accessibility.notSelected))
            }
        }.accessibilityIdentifier("article.row.\(article.slug)")
    }
}

private struct ArticleReaderView: View {
    let article: ArticleDTO; @StateObject private var model: ArticleDetailViewModel
    init(article: ArticleDTO, model: @autoclosure @escaping () -> ArticleDetailViewModel) { self.article = article; _model = StateObject(wrappedValue: model()) }
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                if let detail = model.detail { bodyView(detail) }
                else if model.failed { ContentUnavailableView(L10n.Content.Error.title, systemImage: "wifi.exclamationmark").padding() }
                else { ProgressView().padding(40) }
            }
        }
        .background(AppTheme.background).ignoresSafeArea(edges: .top)
        .toolbar { Button { model.toggleBookmark() } label: { Image(systemName: model.isBookmarked ? "bookmark.fill":"bookmark") }.accessibilityLabel(Text(L10n.Articles.bookmarks)).accessibilityValue(Text(model.isBookmarked ? L10n.Accessibility.selected:L10n.Accessibility.notSelected)) }
        .task { await model.appear() }.accessibilityIdentifier("screen.articleReader")
        .alert(L10n.Content.Error.title,isPresented:Binding(get:{model.errorMessage != nil},set:{if !$0{model.clearError()}})){Button(L10n.Common.close){model.clearError()}}message:{Text(model.errorMessage ?? "")}
    }
    private func bodyView(_ detail: ArticleDetailDTO) -> some View {
        VStack(alignment: .leading, spacing: 26) {
            Text(detail.summary).font(.title3).foregroundStyle(.secondary)
            ForEach(Array(detail.sections.enumerated()), id: \.offset) { _, section in VStack(alignment: .leading) { Text(section.heading).font(.title2.bold()); Text(section.body).lineSpacing(6) } }
            if !detail.related.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.Articles.related).font(.title2.bold())
                    ForEach(detail.related) { related in NavigationLink(value: related) { RelatedArticleCard(article: related) }.buttonStyle(.plain).accessibilityIdentifier("article.related.\(related.slug)") }
                }.accessibilityIdentifier("article.related")
            }
        }.padding(20)
    }
    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [AppTheme.gold.opacity(0.8),AppTheme.graphite], startPoint: .topLeading, endPoint: .bottomTrailing)
            LinearGradient(colors: [.clear,.black.opacity(0.94)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading) { Text(article.title).font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(.white); Label(L10n.Articles.minutesLld(article.readingMinutes), systemImage: "clock").foregroundStyle(.white.opacity(0.8)) }.padding(20)
        }.frame(height: 390).clipped()
    }
}

private struct RelatedArticleCard: View {
    let article: ArticleDTO
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: article.appCategory.icon).font(.title3).foregroundStyle(AppTheme.gold).frame(width: 42, height: 42).background(AppTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) { Text(article.title).font(.headline).multilineTextAlignment(.leading); Text(L10n.Articles.minutesLld(article.readingMinutes)).font(.caption).foregroundStyle(.secondary) }
            Spacer(); Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
        }.padding(14).background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

extension ArticleDTO {
    var appCategory: ArticleCategory { switch category { case "fundamentals":.basics;case "bowls_heat":.heat;default:ArticleCategory(rawValue: category) ?? .basics } }
}
