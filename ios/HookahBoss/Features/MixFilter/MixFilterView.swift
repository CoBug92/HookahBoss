import SwiftUI

struct MixFilterView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: MixFilterViewModel
    private let onApply: (MixFilter) -> Void

    // MARK: - Init

    init(
        model: @autoclosure @escaping () -> MixFilterViewModel,
        onApply: @escaping (MixFilter) -> Void
    ) {
        _model = StateObject(wrappedValue: model())
        self.onApply = onApply
    }

    // MARK: - Layout

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Margin.x(13)) {
                    MixFilterProfilesView(
                        selectedProfiles: model.filter.profiles,
                        onToggle: model.toggle
                    )
                    MixFilterCharacterView(
                        sweetness: $model.filter.sweetness,
                        acidity: $model.filter.acidity,
                        freshness: $model.filter.freshness
                    )
                    MixFilterStrengthView(
                        selection: model.filter.strength,
                        onToggle: model.toggleStrength
                    )
                    MixFilterExclusionsView(
                        excludedFlavor: $model.filter.excludedFlavor
                    )
                }
                .padding(.horizontal, Margin.x9)
                .padding(.top, Margin.x4)
                .padding(.bottom, Margin.x(50))
            }
            .safeAreaInset(edge: .bottom) {
                MixFilterApplyButton(
                    resultCount: model.resultCount,
                    action: apply
                )
            }
            .navigationTitle(L10n.Filters.title)
            .navigationBarTitleDisplayMode(.large)
            .background(AppTheme.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.Common.close) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Filters.reset) {
                        model.reset()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .background(AppTheme.background)
        .accessibilityIdentifier("screen.filters")
    }

    // MARK: - Private methods

    private func apply() {
        onApply(model.filter)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    MixFilterView(
        model: MixFilterViewModel(
            catalog: MixesPreviewData.catalog,
            filter: .empty
        ),
        onApply: { _ in }
    )
}
