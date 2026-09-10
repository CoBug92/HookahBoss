import SwiftUI

struct MixesView: View {
    @EnvironmentObject private var auth:AuthRuntime
    @StateObject private var content = PublicContentStore()
    @State private var isFilterPresented = false
    @State private var filter = MixFilter.empty
    @State private var showResults = false
    @State private var search=""

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(visibleMixes) { mix in
                        mixLink(mix)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(AppTheme.background)
            .overlay { contentOverlay }
            .refreshable { await content.load(locale: .currentApp, force: true) }
            .task { await content.load(locale: .currentApp) }
            .navigationTitle("tab.mixes")
            .searchable(text:$search,prompt:"mix.search")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isFilterPresented = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityLabel(Text("filters.title"))
                    .accessibilityIdentifier("mix.filters")
                }
            }
            .sheet(isPresented: $isFilterPresented) {
                MixFilterView(catalog: personalizedMixes, filter: filter) {
                    filter = $0
                    Task { @MainActor in
                        await Task.yield()
                        showResults = true
                    }
                }
            }
            .navigationDestination(isPresented: $showResults) {
                MixResultsView(filter: $filter, catalog: personalizedMixes)
            }
            .navigationDestination(for: MixPreview.self) { mix in
                MixDetailView(mix: mix,content:content)
            }
        }
    }
    private func mixLink(_ mix:MixPreview)->some View { NavigationLink(value:mix){MixCardView(mix:mix)}.buttonStyle(.plain).accessibilityIdentifier("mix.card.\(mix.id.uuidString)") }
    private var personalizedMixes:[MixPreview] { content.mixes.map{$0.personalized(rating:auth.ratings[$0.id],favorite:auth.favoriteMixIDs.contains($0.id))} }
    private var visibleMixes:[MixPreview]{personalizedMixes.filter{search.isEmpty || ($0.title+" "+$0.flavorTags.joined(separator:" ")).localizedCaseInsensitiveContains(search)}}

    @ViewBuilder private var contentOverlay: some View {
        if content.mixes.isEmpty {
            switch content.state {
            case .idle, .loading: ProgressView()
            case .failed(let message): ContentUnavailableView("content.error.title", systemImage: "wifi.exclamationmark", description: Text(message))
            case .loaded: ContentUnavailableView("content.empty.mixes", systemImage: "square.grid.2x2")
            }
        }
    }

}

private struct MixResultsView: View {
    @Binding var filter: MixFilter
    let catalog: [MixPreview]
    @State private var isFilterPresented = false

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        ScrollView {
            if ideal.isEmpty && possible.isEmpty {
                ContentUnavailableView("filters.empty.title", systemImage: "slider.horizontal.3", description: Text("filters.empty.message"))
                    .padding(.top, 80)
            } else {
                LazyVStack(alignment: .leading, spacing: 24) {
                    resultSection(title: "results.ideal", mixes: ideal)
                    resultSection(title: "results.possible", mixes: possible)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("results.title")
        .accessibilityIdentifier("screen.mixResults")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("results.edit") { isFilterPresented = true }
            }
        }
        .sheet(isPresented: $isFilterPresented) {
            MixFilterView(catalog: catalog, filter: filter) { filter = $0 }
        }
    }

    @ViewBuilder private func resultSection(title: LocalizedStringKey, mixes: [MixPreview]) -> some View {
        if !mixes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(.title2.weight(.semibold))
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(mixes) { mix in
                        NavigationLink(value: mix) { MixCardView(mix: mix) }.buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var ideal: [MixPreview] { MixRanker.ranked(catalog.filter { filter.matchQuality(for: $0) == .ideal }) }
    private var possible: [MixPreview] { MixRanker.ranked(catalog.filter { filter.matchQuality(for: $0) == .possible }) }
}

struct MixCardView: View {
    let mix: MixPreview

    private var ratingColor: Color {
        AppTheme.ratingColor(for: mix.personalRating)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            MixArtwork(palette: mix.palette)

            LinearGradient(
                colors: [.clear, .black.opacity(0.18), .black.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(mix.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .tracking(-0.6)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                FlavorCloud(tags: mix.flavorTags)

                HStack {
                    if let rating = mix.rating {
                        Label(rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                    }
                    Spacer(minLength: 4)
                    Text(mix.strength.title)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
            }
            .foregroundStyle(.white)
            .padding(12)

            VStack {
                HStack(alignment: .top) {
                    if let personalRating = mix.personalRating {
                        Label("\(personalRating)", systemImage: "star.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ratingColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(ratingColor.opacity(0.2), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(ratingColor, lineWidth: 1)
                            }
                    }

                    Spacer()

                    Image(systemName: mix.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 23, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(height: 27)
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
                        .accessibilityHidden(true)
                }
                Spacer()
            }
            .padding(12)
        }
        .aspectRatio(0.86, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [ratingColor.opacity(mix.personalRating == nil ? 0.55 : 1), .black],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
        }
        .accessibilityElement(children: .combine)
    }
}

struct MixDetailView: View {
    @EnvironmentObject private var auth:AuthRuntime
    let mix: MixPreview
    @ObservedObject var content:PublicContentStore
    @State private var hydratedMix:MixPreview?

    @State private var personalRating: Int?
    @State private var isFavorite: Bool
    @State private var isRatingPresented = false
    @State private var suppressRatingSync = false

    init(mix: MixPreview,content:PublicContentStore) {
        self.mix = mix
        self.content=content
        _personalRating = State(initialValue: mix.personalRating)
        _isFavorite = State(initialValue: mix.isFavorite)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                cover
                details
            }
        }
        .background(AppTheme.background)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isRatingPresented) {
            RatingSheet(selection: $personalRating)
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .onAppear { suppressRatingSync=true;personalRating=auth.ratings[mix.id];isFavorite=auth.favoriteMixIDs.contains(mix.id);Task{@MainActor in await Task.yield();suppressRatingSync=false} }
        .task {let locale=APIClient.Locale.currentApp;if let cached=await content.cachedMixDetail(mix.id,locale:locale){hydratedMix=cached};if let fresh=try? await content.mixDetail(mix.id,locale:locale){hydratedMix=fresh}}
        .onChange(of: personalRating) { oldValue,newValue in if oldValue != newValue && !suppressRatingSync { Task { await auth.setRating(newValue,mixId:mix.id);let reconciled=auth.ratings[mix.id];if reconciled != personalRating{suppressRatingSync=true;personalRating=reconciled;await Task.yield();suppressRatingSync=false} } } }
        .alert("content.error.title",isPresented:Binding(get:{auth.libraryError != nil},set:{if !$0{auth.libraryError=nil}})){Button("common.close"){auth.libraryError=nil}} message:{Text(auth.libraryError ?? "")}
        .accessibilityIdentifier("screen.mixDetail")
    }

    private var cover: some View {
        ZStack(alignment: .bottomLeading) {
            MixArtwork(palette: displayedMix.palette)
                .frame(height: 340)

            LinearGradient(
                colors: [.clear, .black.opacity(0.12), .black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(displayedMix.title)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .tracking(-1.2)
                    .lineLimit(2)
                FlavorCloud(tags: displayedMix.flavorTags)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.bottom, 24)

            VStack {
                HStack {
                    NavigationBackButton()
                    Spacer()
                    Button {
                        let action={isFavorite.toggle();Task{await auth.setFavorite(isFavorite,mixId:mix.id);isFavorite=auth.favoriteMixIDs.contains(mix.id)}}
                        if auth.isAuthenticated { action() } else { auth.gate.request(.favorite,resume:action) }
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 27, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(isFavorite ? "favorite.remove" : "favorite.add"))
                    .accessibilityValue(Text(isFavorite ? "accessibility.selected":"accessibility.notSelected"))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 58)
        }
        .frame(height: 340)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 0) {
                MetricView(
                    value: displayedMix.rating.map { "★ " + $0.formatted(.number.precision(.fractionLength(1))) } ?? "—",
                    caption: String(localized: "mix.ratingsCount \(displayedMix.ratingsCount)")
                )
                Divider().frame(height: 34)
                MetricView(value: displayedMix.strength.title, caption: String(localized: "mix.strength"))
                Divider().frame(height: 34)
                Button {
                    if auth.isAuthenticated { isRatingPresented = true } else { auth.gate.request(.rating) { isRatingPresented = true } }
                } label: {
                    MetricView(
                        value: personalRating.map { "★ \($0)" } ?? String(localized: "mix.rate"),
                        caption: String(localized: "mix.yourRating"),
                        emphasized: personalRating == nil
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("mix.yourRating"))
                .accessibilityValue(Text(personalRating.map(String.init) ?? String(localized:"accessibility.notRated")))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("mix.composition")
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("mix.composition")

                HStack(alignment: .top, spacing: 8) {
                    ForEach(displayedMix.ingredients) { ingredient in
                        IngredientCard(ingredient: ingredient, palette: displayedMix.palette)
                    }
                }

                Text("mix.percentageNote")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 32)
    }
    private var displayedMix:MixPreview { hydratedMix ?? mix }
}

private struct IngredientCard: View {
    let ingredient: MixIngredient
    let palette: MixPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                MixArtwork(palette: palette)
                    .frame(height: 44)
                Text("\(ingredient.percentage)%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.brandAndLine.uppercased())
                    .font(.system(size: 9, weight: .medium))
                    .tracking(0.4)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(ingredient.flavor)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
            }
            .padding(9)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}

private struct MetricView: View {
    let value: String
    let caption: String
    var emphasized = false

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(emphasized ? AppTheme.gold : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

private struct RatingSheet: View {
    @Binding var selection: Int?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("rating.title")
                    .font(.title2.weight(.semibold))
                Text("rating.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { score in
                    Button {
                        selection = score
                        dismiss()
                    } label: {
                        Image(systemName: "star.fill")
                            .font(.title3)
                            .foregroundStyle(selection == score ? AppTheme.ratingColor(for: score) : Color.secondary)
                            .frame(width: 46, height: 46)
                            .background(AppTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("\(score)"))
                    .accessibilityValue(Text(selection == score ? "accessibility.selected":"accessibility.notSelected"))
                }
            }
        }
        .padding(24)
    }
}

private struct FlavorCloud: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tags.prefix(3), id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 9, weight: .medium))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.12), in: Capsule())
                    .overlay { Capsule().stroke(.white.opacity(0.25), lineWidth: 0.8) }
            }
        }
    }
}

struct MixArtwork: View {
    let palette: MixPalette

    var body: some View {
        ZStack {
            if let image=ArtworkResource.image(named:palette.artworkFilename) { Image(uiImage:image).resizable().scaledToFill() }
            else { AppTheme.card }
            LinearGradient(colors:[.clear,.black.opacity(0.22)],startPoint:.top,endPoint:.bottom)
            Circle().fill(.white.opacity(0.12)).frame(width:110,height:110).blur(radius:7).offset(x:70,y:-65)
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

enum ArtworkResource {
    static func url(named name:String,bundle:Bundle = .main)->URL? {
        bundle.url(forResource:name,withExtension:"png",subdirectory:"Artwork") ?? bundle.url(forResource:name,withExtension:"png")
    }
    static func image(named name:String,bundle:Bundle = .main)->UIImage? {
        guard let url=url(named:name,bundle:bundle),let data=try? Data(contentsOf:url) else{return nil};return UIImage(data:data)
    }
}

private struct NavigationBackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.black.opacity(0.28), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("common.back"))
    }
}
