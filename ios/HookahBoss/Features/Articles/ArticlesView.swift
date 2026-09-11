import SwiftUI

struct ArticlesView: View {
    @StateObject private var model: ArticlesViewModel
    let makeDetailModel: (ArticleDTO) -> ArticleDetailViewModel

    init(model: @autoclosure @escaping () -> ArticlesViewModel,
         makeDetailModel: @escaping (ArticleDTO) -> ArticleDetailViewModel) {
        _model = StateObject(wrappedValue: model())
        self.makeDetailModel = makeDetailModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center) {
                        Text(L10n.Tab.articles)
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .tracking(-0.5)
                        Spacer()
                        NavigationLink(value: ArticleDestination.bookmarks) {
                            Image(systemName: "bookmark")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(AppTheme.gold)
                                .frame(width: 36, height: 36)
                        }
                        .accessibilityLabel(Text(L10n.Articles.bookmarks))
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(ArticleCategory.allCases) { category in
                                NavigationLink(value: category) {
                                    CategoryCard(category: category, count: model.articles(in: category).count)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .contentMargins(.trailing, 12, for: .scrollContent)

                    HStack(alignment: .firstTextBaseline) {
                        Text(ArticlesPageCopy.editorChoice)
                            .font(.title3.weight(.bold))
                        Spacer()
                        HStack(spacing: 5) {
                            Text(L10n.Common.all)
                            Image(systemName: "arrow.right")
                        }
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.gold)
                    }

                    if !model.articles.isEmpty {
                        ArticleEditorialGrid(
                            articles: Array(model.articles.prefix(3))
                        )
                    }

                    Text(ArticlesPageCopy.continueReading)
                        .font(.title3.weight(.bold))
                        .padding(.top, 4)

                    LazyVStack(spacing: 10) {
                        ForEach(Array(model.articles.dropFirst(3).prefix(3))) { article in
                            ArticleRecommendationRow(
                                article: article,
                                bookmarked: model.isBookmarked(article),
                                toggle: { model.toggleBookmark(article) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .overlay { if model.isLoading && model.articles.isEmpty { ProgressView() } }
            .refreshable { await model.refresh() }.task { await model.appear() }
            .toolbar(.hidden,for:.navigationBar)
            .navigationDestination(for: ArticleCategory.self) { category in ArticleListView(content: .category(category), model: model) }
            .navigationDestination(for: ArticleDestination.self) { _ in ArticleListView(content: .bookmarks, model: model) }
            .navigationDestination(for: ArticleDTO.self) { article in ArticleReaderView(article: article, model: makeDetailModel(article)) }
            .onAppear { model.syncLibraryState() }
            .alert(L10n.Content.Error.title,isPresented:Binding(get:{model.errorMessage != nil},set:{if !$0{model.clearError()}})){Button(L10n.Common.close){model.clearError()}}message:{Text(model.errorMessage ?? "")}
            .background(AppTheme.background).accessibilityIdentifier("screen.articles")
        }
    }
}

private struct ArticleArtwork:View {let category:ArticleCategory;var body:some View{ZStack{if let image=ArtworkResource.image(for:category){Image(uiImage:image).resizable().scaledToFill()}else{LinearGradient(colors:[AppTheme.gold,.brown],startPoint:.topLeading,endPoint:.bottomTrailing)}}.clipped().accessibilityHidden(true)}}

private struct ArticleSpecificArtwork: View {
    let article: ArticleDTO
    var body: some View {
        ZStack {
            if let image = ArtworkResource.image(for: article) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [AppTheme.gold, .brown], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

private enum ArticleDestination: Hashable { case bookmarks }

private enum ArticlesPageCopy {
    static var editorChoice: String { AppLocale.currentApp == .ru ? "Выбор редакции" : "Editor's choice" }
    static var continueReading: String { AppLocale.currentApp == .ru ? "Продолжить чтение" : "Continue reading" }
}

private struct CategoryCard: View {
    let category: ArticleCategory; let count: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: category.icon)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(AppTheme.gold)
            Spacer(minLength: 6)
            Text(category.title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(L10n.Articles.countLld(count))
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .padding(.top, 3)
        }
        .padding(12)
        .frame(width: 112, height: 92, alignment: .leading)
        .appCard(cornerRadius: 16)
    }
}

private struct ArticleEditorialGrid: View {
    let articles: [ArticleDTO]
    private let gridHeight: CGFloat = 258
    private let spacing: CGFloat = 10

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width - spacing
            HStack(alignment: .top, spacing: spacing) {
                if let article = articles.first {
                    ArticleEditorialCard(
                        article: article,
                        height: gridHeight,
                        prominent: true
                    )
                    .frame(width: availableWidth * 0.56)
                }
                VStack(spacing: spacing) {
                    ForEach(Array(articles.dropFirst().prefix(2))) { article in
                        ArticleEditorialCard(
                            article: article,
                            height: (gridHeight - spacing) / 2,
                            prominent: false
                        )
                    }
                }
                .frame(width: availableWidth * 0.44)
            }
        }
        .frame(height: gridHeight)
    }
}

private struct ArticleEditorialCard: View {
    let article: ArticleDTO
    let height: CGFloat
    let prominent: Bool

    var body: some View {
        NavigationLink(value: article) {
            ZStack(alignment: .bottomLeading) {
                ArticleSpecificArtwork(article: article)
                LinearGradient(
                    colors: [.clear, .black.opacity(0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                VStack(alignment: .leading, spacing: prominent ? 9 : 6) {
                    Text(editorialMeta)
                        .font(.system(size: prominent ? 10 : 9, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(AppTheme.cream)
                        .lineLimit(prominent ? 2 : 1)
                    Text(article.title)
                        .font(.system(size: prominent ? 17 : 13, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(prominent ? 3 : 2)
                        .minimumScaleFactor(0.86)
                }
                .padding(prominent ? 16 : 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: prominent ? 21 : 18, style: .continuous))
    }

    private var editorialMeta: String {
        let category = article.appCategory.title.uppercased()
        guard prominent else { return category }
        return "\(category) · \(L10n.Articles.minutesLld(article.readingMinutes).uppercased())"
    }

}

private struct ArticleRecommendationRow: View {
    let article: ArticleDTO
    let bookmarked: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(value: article) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(article.appCategory.title.uppercased()) · \(L10n.Articles.minutesLld(article.readingMinutes).uppercased())")
                        .font(.caption2.weight(.semibold))
                        .tracking(0.4)
                        .foregroundStyle(AppTheme.gold)
                        .lineLimit(1)
                    Text(article.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: toggle) {
                Image(systemName: bookmarked ? "bookmark.fill" : "bookmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.gold)
                    .frame(width: 36, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.Articles.bookmarks))
            .accessibilityValue(Text(bookmarked ? L10n.Accessibility.selected : L10n.Accessibility.notSelected))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .appCard(cornerRadius: 17)
        .accessibilityIdentifier("article.row.\(article.slug)")
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
            Text(detail.summary).font(.title3.weight(.medium)).foregroundStyle(.secondary).lineSpacing(5)
            ForEach(Array(detail.sections.enumerated()), id: \.offset) { _, section in VStack(alignment: .leading,spacing:10) { Text(section.heading).font(.title2.bold()); Text(section.body).font(.system(.body,design:.serif)).lineSpacing(7).foregroundStyle(.primary.opacity(0.82)) } }
            if !detail.related.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.Articles.related).font(.title2.bold())
                    ForEach(detail.related) { related in NavigationLink(value: related) { RelatedArticleCard(article: related) }.buttonStyle(.plain).accessibilityIdentifier("article.related.\(related.slug)") }
                }.accessibilityIdentifier("article.related")
            }
        }.padding(20).background(AppTheme.background,in:UnevenRoundedRectangle(topLeadingRadius:28,topTrailingRadius:28)).offset(y:-24)
    }
    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            ArticleArtwork(category:article.appCategory)
            LinearGradient(colors: [.clear,.black.opacity(0.94)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading,spacing:9) { Text(article.appCategory.title.uppercased()).font(.caption2.bold()).tracking(1.2).foregroundStyle(AppTheme.cream);Text(article.title).font(.system(size: 35, weight: .bold, design: .serif)).foregroundStyle(.white); Label(L10n.Articles.minutesLld(article.readingMinutes), systemImage: "clock").font(.caption).foregroundStyle(.white.opacity(0.8)) }.padding(.horizontal,20).padding(.bottom,46)
        }.frame(height: 360).clipped()
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
