import SwiftUI

struct PersonalMixDetailView: View {

    // MARK: - Properties

    @StateObject private var model: PersonalMixDetailViewModel

    init(model: @autoclosure @escaping () -> PersonalMixDetailViewModel) {
        _model = StateObject(wrappedValue: model())
    }

    // MARK: - Layout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Margin.x(12)) {
                PersonalMixDetailHeroView(
                    mix: model.mix,
                    title: model.title,
                    componentsCount: model.components.count,
                    isApproximate: model.isApproximate
                )

                PersonalMixCompositionView(components: model.components)
            }
            .padding(.bottom, Margin.x(16))
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
        .navigationTitle(model.title)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(AccessibilityID.personalMixDetail)
    }

}

// MARK: - Preview

#Preview {
    NavigationStack {
        PersonalMixDetailView(
            model: PersonalMixDetailViewModel(
                mix: PersonalMixPreviewData.tropical
            )
        )
    }
}
