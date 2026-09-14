import SwiftUI

struct InventoryAddView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var search = TechnicalString.empty
    @State private var showPrivate = false
    let products: [TobaccoProductDTO]
    let onAdd: (TobaccoProductDTO) -> Void
    let onCreatePrivate: (String, String?, String, [String], @escaping (Bool) -> Void) -> Void

    // MARK: - Computed properties

    private var filtered: [TobaccoProductDTO] {
        products.filter {
            search.isEmpty
                || [$0.name, $0.brandName, $0.lineName]
                    .joined(separator: TechnicalString.space)
                    .localizedCaseInsensitiveContains(search)
        }
    }

    // MARK: - Layout

    var body: some View {
        NavigationStack {
            List(filtered) { product in
                Button {
                    onAdd(product)
                    dismiss()
                } label: {
                    VStack(
                        alignment: .leading,
                        spacing: Margin.x4
                    ) {
                        Text(product.name)
                        Text(
                            [product.brandName, product.lineName]
                                .joined(separator: TechnicalString.bulletSeparator)
                        )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(AppTheme.card)
            }
            .scrollIndicators(.hidden)
            .searchable(text: $search, prompt: L10n.Create.search)
            .navigationTitle(L10n.Inventory.add)
            .appScreenBackground()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.Common.close) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Inventory.addPrivate) {
                        showPrivate = true
                    }
                }
            }
            .sheet(isPresented: $showPrivate) {
                PrivateProductAddView(onCreate: onCreatePrivate)
            }
        }
    }
}

// MARK: - Preview

#Preview("Content") {
    InventoryAddView(
        products: TobaccoProductPreviewData.catalog,
        onAdd: { _ in },
        onCreatePrivate: { _, _, _, _, completion in
            completion(true)
        }
    )
}

#Preview("Empty") {
    InventoryAddView(
        products: [],
        onAdd: { _ in },
        onCreatePrivate: { _, _, _, _, completion in
            completion(true)
        }
    )
}
