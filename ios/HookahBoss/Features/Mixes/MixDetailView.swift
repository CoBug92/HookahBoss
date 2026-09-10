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
                details
            }
        }
        .background(AppTheme.background)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
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
        .frame(height: 340)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 0) {
                MetricView(
                    value: displayedMix.rating.map { "★ " + $0.formatted(.number.precision(.fractionLength(1))) } ?? "—",
                    caption: L10n.Mix.ratingsCountLld(displayedMix.ratingsCount)
                )
                Divider().frame(height: 34)
                MetricView(value: displayedMix.strength.title, caption: L10n.Mix.strength)
                Divider().frame(height: 34)
                Button {
                    model.requestRating { isRatingPresented = true }
                } label: {
                    MetricView(
                        value: personalRatingValue,
                        caption: L10n.Mix.yourRating,
                        emphasized: model.personalRating == nil
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.Mix.yourRating))
                .accessibilityValue(Text(personalRatingAccessibilityValue))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Mix.composition)
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier(AccessibilityID.mixComposition)

                HStack(alignment: .top, spacing: 8) {
                    ForEach(displayedMix.ingredients) { ingredient in
                        IngredientCard(ingredient: ingredient, palette: displayedMix.palette)
                    }
                }

                Text(L10n.Mix.percentageNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 32)
    }
    private var displayedMix:MixPreview { model.displayedMix }
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
