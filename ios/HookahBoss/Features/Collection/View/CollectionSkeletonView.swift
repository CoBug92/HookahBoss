import SwiftUI

struct CollectionSkeletonView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: Margin.x6) {
                        counter
                        counter
                    }
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    row
                    row
                }

                Section {
                    row
                    row
                    row
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle(L10n.Tab.collection)
            .appScreenBackground()
            .accessibilityHidden(true)
        }
    }

    private var counter: some View {
        RoundedRectangle(cornerRadius: .counterCornerRadius)
            .fill(AppTheme.elevated)
            .frame(maxWidth: .infinity)
            .frame(height: .counterHeight)
    }

    private var row: some View {
        RoundedRectangle(cornerRadius: .rowCornerRadius)
            .fill(AppTheme.elevated)
            .frame(height: .rowHeight)
    }
}

// MARK: - Constants

private extension CGFloat {
    static let counterCornerRadius: CGFloat = 18
    static let counterHeight: CGFloat = 132
    static let rowCornerRadius: CGFloat = 12
    static let rowHeight: CGFloat = 62
}

// MARK: - Preview

#Preview("Light") {
    CollectionSkeletonView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CollectionSkeletonView()
        .preferredColorScheme(.dark)
}
