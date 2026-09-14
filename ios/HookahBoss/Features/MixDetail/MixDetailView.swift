import SwiftUI

struct MixDetailView: View {

    // MARK: - Properties

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var model: MixDetailViewModel
    @State private var isRatingPresented = false
    @State private var isPresentationVisible = false

    // MARK: - Init

    init(model: @autoclosure @escaping () -> MixDetailViewModel) {
        _model = StateObject(wrappedValue: model())
    }

    // MARK: - Layout

    var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                MixDetailCoverView(
                    palette: model.displayedMix.palette,
                    isAnimated: isPresentationVisible && !reduceMotion
                )
                MixDetailContentView(
                    mix: model.displayedMix,
                    personalRating: model.personalRating,
                    isPresented: isPresentationVisible,
                    onRate: { model.requestRating { isRatingPresented = true } }
                )
                .offset(y: -Margin.x(64))
            }
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(model.displayedMix.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.requestFavoriteToggle()
                } label: {
                    Image(
                        systemName: model.isFavorite ? AppSymbol.favoriteFilled : AppSymbol.favorite
                    )
                }
                .accessibilityLabel(
                    Text(model.isFavorite ? L10n.Favorite.remove : L10n.Favorite.add)
                )
                .accessibilityValue(
                    Text(
                        model.isFavorite
                            ? L10n.Accessibility.selected
                            : L10n.Accessibility.notSelected
                    )
                )
            }
        }
        .sheet(isPresented: $isRatingPresented) {
            MixRatingSheet(
                selection: Binding(
                    get: { model.personalRating },
                    set: { score in model.submitRatingIntent(score) }
                )
            )
            .presentationDetents([.height(.ratingSheetHeight)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(.sheetCornerRadius)
        }
        .task { await model.appear() }
        .task { await presentContent() }
        .alert(
            L10n.Content.Error.title,
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.dismissError() } }
            )
        ) {
            Button(L10n.Common.close) {
                model.dismissError()
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .accessibilityIdentifier(AccessibilityID.mixDetail)
        .mixNavigationTransition(sourceID: model.displayedMix.id)
    }

    // MARK: - Private methods

    private func presentContent() async {
        guard !reduceMotion else {
            isPresentationVisible = true
            return
        }

        try? await Task.sleep(for: .navigationTransitionDelay)
        guard !Task.isCancelled else { return }
        isPresentationVisible = true
    }
}

private extension Duration {
    static let navigationTransitionDelay = Duration.milliseconds(250)
}

private extension CGFloat {
    static let ratingSheetHeight: CGFloat = 260
    static let sheetCornerRadius: CGFloat = 28
}

// MARK: - Preview

#Preview {
    let content = PreviewPublicCatalogService()
    let library = PreviewAuthLibraryService()

    NavigationStack {
        MixDetailView(
            model: MixDetailViewModel(
                mix: MixesPreviewData.featured,
                content: content,
                auth: library
            )
        )
    }
}
