import SwiftUI
import UIKit

struct MixesView: View {
    @EnvironmentObject private var navigation: AppNavigation
    @StateObject private var model: MixCatalogViewModel
    @State private var filters = false
    @State private var results = false
    @State private var handledFiltersRequest = 0
    let makeMixDetailModel: (MixPreview) -> MixDetailViewModel
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    init(model: @autoclosure @escaping () -> MixCatalogViewModel,
         makeMixDetailModel: @escaping (MixPreview) -> MixDetailViewModel) {
        _model = StateObject(wrappedValue: model())
        self.makeMixDetailModel = makeMixDetailModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(model.visibleMixes) { mix in
                            NavigationLink(value: mix) { MixCardView(mix: mix) }.buttonStyle(.plain)
                                .accessibilityIdentifier("mix.card.\(mix.id.uuidString)")
                        }
                    }
                }.padding(.horizontal, 16).padding(.bottom, 30)
            }
            .background(AppTheme.background)
            .navigationTitle(L10n.Tab.mixes)
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $model.search,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: L10n.Mix.search
            )
            .scrollDismissesKeyboard(.immediately)
            .simultaneousGesture(TapGesture().onEnded { dismissKeyboard() })
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { filters = true } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityLabel(Text(L10n.Filters.title))
                    .accessibilityIdentifier("mix.filters")
                }
            }
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .overlay { if model.isLoading && model.catalog.isEmpty { ProgressView().controlSize(.large) } }
            .refreshable { await model.refresh() }.task { await model.appear() }.onAppear { model.syncLibraryState() }
            .onAppear { presentRequestedFilters() }
            .onChange(of: navigation.mixFiltersRequest) { _, _ in presentRequestedFilters() }
            .sheet(isPresented: $filters) { MixFilterView(model: MixFilterViewModel(catalog: model.catalog, filter: model.filter)) { model.apply($0); results = true } }
            .navigationDestination(isPresented: $results) { MixResultsView(model: model) }
            .navigationDestination(for: MixPreview.self) { MixDetailView(model: makeMixDetailModel($0)) }
        }
    }

    private func presentRequestedFilters() {
        guard navigation.mixFiltersRequest > handledFiltersRequest else { return }
        handledFiltersRequest = navigation.mixFiltersRequest
        filters = true
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

private struct MixResultsView: View {
    @ObservedObject var model: MixCatalogViewModel
    @State private var filters = false
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    var body: some View {
        ScrollView {
            if model.ideal.isEmpty && model.possible.isEmpty {
                AppEmptyState(icon: "slider.horizontal.3", title: L10n.Filters.Empty.title, message: L10n.Filters.Empty.message).padding(18)
            } else {
                LazyVStack(alignment: .leading, spacing: 28) { section(L10n.Results.ideal, model.ideal); section(L10n.Results.possible, model.possible) }.padding(16)
            }
        }.background(AppTheme.background).navigationTitle(L10n.Results.title).accessibilityIdentifier("screen.mixResults")
            .toolbar { Button(L10n.Results.edit) { filters = true } }
            .sheet(isPresented: $filters) { MixFilterView(model: MixFilterViewModel(catalog: model.catalog, filter: model.filter), onApply: model.apply) }
    }
    @ViewBuilder private func section(_ title: String, _ mixes: [MixPreview]) -> some View {
        if !mixes.isEmpty { VStack(alignment: .leading, spacing: 12) { AppSectionHeader(title: title); LazyVGrid(columns: columns, spacing: 12) { ForEach(mixes) { mix in NavigationLink(value: mix) { MixCardView(mix: mix) }.buttonStyle(.plain) } } } }
    }
}
