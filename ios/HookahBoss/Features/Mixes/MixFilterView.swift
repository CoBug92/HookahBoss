import SwiftUI

struct MixFilterView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var model: MixFilterViewModel
    let onApply: (MixFilter) -> Void

    init(model: @autoclosure @escaping () -> MixFilterViewModel, onApply: @escaping (MixFilter) -> Void) {
        _model = StateObject(wrappedValue: model())
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    profileSection
                    characterSection
                    strengthSection
                    exclusionsSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    onApply(model.filter)
                    dismiss()
                } label: {
                    Text(L10n.Filters.showResultsLld(resultCount))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .foregroundStyle(.white)
                        .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("filters.apply")
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .navigationTitle(L10n.Filters.title)
            .navigationBarTitleDisplayMode(.large)
            .background(AppTheme.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.Common.close) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Filters.reset) { model.reset() }
                        .foregroundStyle(.secondary)
                }
            }
        }
        .background(AppTheme.background)
        .accessibilityIdentifier("screen.filters")
    }

    private var profileSection: some View {
        FilterSection(title: L10n.Filters.profiles, subtitle: L10n.Filters.multiple) {
            FlowLayout(spacing: 8) {
                ForEach(FlavorProfile.allCases) { profile in
                    FilterChip(title: profile.title, isSelected: model.filter.profiles.contains(profile)) { model.toggle(profile) }
                }
            }
        }
    }

    private var characterSection: some View {
        FilterSection(title: L10n.Filters.character) {
            VStack(spacing: 12) {
                IntensityPicker(title: L10n.Filters.sweetness, selection: $model.filter.sweetness)
                IntensityPicker(title: L10n.Filters.acidity, selection: $model.filter.acidity)
                IntensityPicker(title: L10n.Filters.freshness, selection: $model.filter.freshness)
            }
        }
    }

    private var strengthSection: some View {
        FilterSection(title: L10n.Filters.strength) {
            HStack(spacing: 8) {
                ForEach([MixStrength.light, .medium, .strong], id: \.self) { option in
                    FilterChip(title: option.title, isSelected: model.filter.strength == option) { model.toggleStrength(option) }
                }
            }
        }
    }

    private var exclusionsSection: some View {
        FilterSection(title: L10n.Filters.exclude, subtitle: L10n.Filters.excludeHint) {
            HStack(spacing: 10) {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.secondary)
                TextField(L10n.Filters.excludePlaceholder, text: $model.filter.excludedFlavor)
                    .textInputAutocapitalization(.never)
            }
            .padding(13)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
    }

    private var resultCount: Int {
        model.resultCount
    }
}

private struct FilterSection<Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
            }
            content
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .foregroundStyle(isSelected ? AppTheme.gold : Color.secondary)
                .background(isSelected ? AppTheme.gold.opacity(0.14) : AppTheme.card)
                .clipShape(Capsule())
                .overlay { Capsule().stroke(isSelected ? AppTheme.gold : .clear, lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }
}

private struct IntensityPicker: View {
    let title: String
    @Binding var selection: FlavorIntensity

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.subheadline)
                .frame(width: 84, alignment: .leading)

            Picker(title, selection: $selection) {
                ForEach(FlavorIntensity.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, point) in result.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, points: [CGPoint]) {
        let width = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var points: [CGPoint] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (CGSize(width: width, height: y + rowHeight), points)
    }
}
