import SwiftUI

struct PersonalMixDetailView: View {
    @StateObject private var model: PersonalMixDetailViewModel

    init(model: @autoclosure @escaping () -> PersonalMixDetailViewModel) {
        _model = StateObject(wrappedValue: model())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.Mix.composition)
                        .font(.title2.weight(.semibold))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 10) {
                            ForEach(model.components) { component in
                                componentCard(component)
                            }
                        }
                    }
                    .accessibilityIdentifier(AccessibilityID.personalMixComposition)
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 32)
        }
        .background(AppTheme.background)
        .navigationTitle(model.title)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(AccessibilityID.personalMixDetail)
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            PersonalMixArtwork(mix: model.mix)
            LinearGradient(colors: [.clear, .black.opacity(0.88)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 8) {
                if model.isApproximate {
                    Label(L10n.PersonalMix.approximate, systemImage: "approximately")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.gold)
                }
                Text(model.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                Text(L10n.Collection.componentsLld(model.components.count))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(20)
        }
        .frame(height: 280)
        .clipped()
    }

    private func componentCard(_ component: PersonalMixDetailViewModel.Component) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(component.flavor)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            if let brandAndLine = component.brandAndLine {
                Text(brandAndLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            Text(component.percentage.map { "\($0)%" } ?? "—")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.gold)
        }
        .padding(14)
        .frame(width: 148, height: 154, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
