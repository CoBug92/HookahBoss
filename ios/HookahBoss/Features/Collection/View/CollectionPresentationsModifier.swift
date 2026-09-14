import SwiftUI

struct CollectionPresentationsModifier: ViewModifier {
    @ObservedObject var model: CollectionViewModel
    let adminView: () -> AnyView

    func body(content: Content) -> some View {
        content
            .alert(
                L10n.Content.Error.title,
                isPresented: Binding(
                    get: { model.errorMessage != nil },
                    set: { if !$0 { model.clearError() } }
                )
            ) {
                Button(L10n.Common.close) {
                    model.clearError()
                }
            } message: {
                Text(model.errorMessage ?? TechnicalString.empty)
            }
            .sheet(isPresented: $model.showAddInventory) {
                InventoryAddView(
                    products: model.products,
                    onAdd: model.add,
                    onCreatePrivate: model.createPrivate
                )
            }
            .confirmationDialog(
                L10n.Account.settings,
                isPresented: $model.showSettings
            ) {
                Button(L10n.Account.logout) {
                    model.logout()
                }
                Button(L10n.Account.delete, role: .destructive) {
                    model.confirmDelete = true
                }
                Button(L10n.Common.cancel, role: .cancel) {}
            }
            .sheet(isPresented: $model.showAdmin) {
                adminView()
            }
            .alert(
                L10n.Account.Delete.confirm,
                isPresented: $model.confirmDelete
            ) {
                Button(L10n.Account.delete, role: .destructive) {
                    model.deleteAccount()
                }
                Button(L10n.Common.cancel, role: .cancel) {}
            } message: {
                Text(L10n.Account.Delete.message)
            }
            .alert(
                L10n.Account.Delete.ProviderUnavailable.title,
                isPresented: $model.showProviderUnavailable
            ) {
                Button(L10n.Common.close) {}
            } message: {
                Text(L10n.Account.Delete.ProviderUnavailable.message)
            }
    }
}

extension View {
    func collectionPresentations(
        model: CollectionViewModel,
        adminView: @escaping () -> AnyView
    ) -> some View {
        modifier(
            CollectionPresentationsModifier(
                model: model,
                adminView: adminView
            )
        )
    }
}
