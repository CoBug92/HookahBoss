import SwiftUI
struct MixDetailView: View {
    @StateObject private var model:MixDetailViewModel
    @State private var isRatingPresented = false

    init(model: @autoclosure @escaping () -> MixDetailViewModel) {
        _model = StateObject(wrappedValue: model())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                cover
                details.offset(y:-22)
            }
        }
        .coordinateSpace(name: "mixDetailScroll")
        .background(AppTheme.background)
        .ignoresSafeArea(edges: .top)
        .navigationTitle(displayedMix.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .background(InteractivePopGestureEnabler())
        .sheet(isPresented: $isRatingPresented) {
            RatingSheet(selection: Binding(
                get: { model.personalRating },
                set: { score in model.submitRatingIntent(score) }
            ))
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .task { await model.appear() }
        .alert(L10n.Content.Error.title,isPresented:Binding(get:{model.errorMessage != nil},set:{if !$0{model.dismissError()}})){Button(L10n.Common.close){model.dismissError()}} message:{Text(model.errorMessage ?? "")}
        .accessibilityIdentifier("screen.mixDetail")
    }

    private var cover: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { proxy in
                let offset = proxy.frame(in: .named("mixDetailScroll")).minY
                MixArtwork(palette: displayedMix.palette)
                    .frame(height: 410 + max(offset, 0))
                    .offset(y: offset > 0 ? -offset : -offset * 0.28)
            }

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.36), location: 0),
                    .init(color: .clear, location: 0.42)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                HStack {
                    NavigationBackButton()
                    Spacer()
                    Button {
                        model.requestFavoriteToggle()
                    } label: {
                        Image(systemName: model.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 27, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(model.isFavorite ? L10n.Favorite.remove : L10n.Favorite.add))
                    .accessibilityValue(Text(model.isFavorite ? L10n.Accessibility.selected:L10n.Accessibility.notSelected))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 58)
        }
        .frame(height: 410)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 0) {
                MetricView(
                    value: displayedMix.rating.map { "★ " + $0.formatted(.number.precision(.fractionLength(1))) } ?? "—",
                    caption: displayedMix.ratingsCount > 0 ? L10n.Mix.ratingsCountLld(displayedMix.ratingsCount) : nil
                )
                Divider().frame(height: 34)
                MetricView(value: displayedMix.strength.detailTitle, caption: L10n.Mix.strength)
                Divider().frame(height: 34)
                Button {
                    model.requestRating { isRatingPresented = true }
                } label: {
                    MetricView(
                        value: personalRatingValue,
                        caption: nil,
                        emphasized: model.personalRating == nil
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.Mix.yourRating))
                .accessibilityValue(Text(personalRatingAccessibilityValue))
            }.padding(.vertical,14).appCard(cornerRadius:18)

            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Mix.composition)
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier(AccessibilityID.mixComposition)

                LazyVGrid(columns: ingredientColumns, spacing: 10) {
                    ForEach(displayedMix.ingredients) { ingredient in
                        IngredientCard(ingredient: ingredient)
                    }
                }

            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 24)
        .padding(.bottom, 32)
        .background(AppTheme.background, in: UnevenRoundedRectangle(topLeadingRadius:28,topTrailingRadius:28))
    }
    private var displayedMix:MixPreview { model.displayedMix }
    private var ingredientColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }
    private var personalRatingValue: String {
        guard let rating = model.personalRating else { return L10n.Mix.rate }
        return "★ \(rating)"
    }
    private var personalRatingAccessibilityValue: String {
        guard let rating = model.personalRating else { return L10n.Accessibility.notRated }
        return String(rating)
    }
}

private struct IngredientCard: View {
    let ingredient: MixIngredient

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(ingredient.percentage)%")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.gold)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.brandAndLine.uppercased())
                    .font(.caption2.weight(.medium))
                    .tracking(0.4)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(ingredient.flavor)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}

private struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            guard let navigationController = viewController.navigationController else { return }
            navigationController.interactivePopGestureRecognizer?.isEnabled = navigationController.viewControllers.count > 1
            navigationController.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

private struct MetricView: View {
    let value: String
    let caption: String?
    var emphasized = false

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(emphasized ? AppTheme.gold : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
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
                Text(L10n.Rating.title)
                    .font(.title2.weight(.semibold))
                Text(L10n.Rating.subtitle)
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
                    .accessibilityValue(Text(selection == score ? L10n.Accessibility.selected:L10n.Accessibility.notSelected))
                }
            }
        }
        .padding(24)
    }
}

struct FlavorCloud: View {
    let tags: [String]

    var body: some View {
        FlavorFlowLayout(spacing: 4) {
            ForEach(tags.prefix(3), id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.12), in: Capsule())
                    .overlay { Capsule().stroke(.white.opacity(0.25), lineWidth: 0.8) }
            }
        }
    }
}

private struct FlavorFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        arrange(subviews: subviews, width: proposal.width ?? .infinity).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = arrange(subviews: subviews, width: bounds.width)
        for item in result.items {
            subviews[item.index].place(
                at: CGPoint(x: bounds.minX + item.origin.x, y: bounds.minY + item.origin.y),
                proposal: ProposedViewSize(item.size)
            )
        }
    }

    private func arrange(subviews: Subviews, width: CGFloat) -> (size: CGSize, items: [Item]) {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var items: [Item] = []

        for index in subviews.indices {
            let measured = subviews[index].sizeThatFits(.unspecified)
            let itemWidth = min(measured.width, width)
            if x > 0, x + itemWidth > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            let size = CGSize(width: itemWidth, height: measured.height)
            items.append(Item(index: index, origin: CGPoint(x: x, y: y), size: size))
            x += itemWidth + spacing
            rowHeight = max(rowHeight, measured.height)
        }

        return (CGSize(width: width.isFinite ? width : x, height: y + rowHeight), items)
    }

    private struct Item {
        let index: Int
        let origin: CGPoint
        let size: CGSize
    }
}

struct MixArtwork: View {
    let palette: MixPalette

    var body: some View {
        ZStack {
            if let image=ArtworkResource.image(for:palette) { Image(uiImage:image).resizable().scaledToFill() }
            else { AppTheme.card }
            LinearGradient(colors:[.clear,.black.opacity(0.22)],startPoint:.top,endPoint:.bottom)
            Circle().fill(.white.opacity(0.12)).frame(width:110,height:110).blur(radius:7).offset(x:70,y:-65)
        }
        .clipped()
        .accessibilityHidden(true)
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
        .accessibilityLabel(Text(L10n.Common.back))
    }
}
