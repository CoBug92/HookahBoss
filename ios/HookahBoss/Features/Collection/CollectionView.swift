import SwiftUI

struct CollectionView: View {
    @EnvironmentObject private var navigation: AppNavigation
    @StateObject private var model: CollectionViewModel
    let makeMixDetail: (MixPreview) -> MixDetailViewModel
    let makeMatches: () -> InventoryMatchViewModel
    let adminView: () -> AnyView

    init(model: @autoclosure @escaping () -> CollectionViewModel,
         makeMixDetail: @escaping (MixPreview) -> MixDetailViewModel,
         makeMatches: @escaping () -> InventoryMatchViewModel,
         adminView: @escaping () -> AnyView) {
        _model = StateObject(wrappedValue: model())
        self.makeMixDetail = makeMixDetail; self.makeMatches = makeMatches; self.adminView = adminView
    }

    var body: some View {
        Group { if model.showsSignedOutPlaceholders { SignedOutCollectionView(model: model) } else { accountContent } }
            .onAppear { model.appear() }
    }

    private var accountContent: some View {
        NavigationStack {
            List {
                Section { HStack(spacing:12) {
                    NavigationLink(value:CollectionSection.favorites){counter(title:L10n.Collection.favorites,value:String(model.favoriteMixIDs.count),icon:"heart.fill")}.buttonStyle(.plain)
                    NavigationLink(value:CollectionSection.personal){counter(title:L10n.Collection.personalMixes,value:String(model.personalMixes.count),icon:"square.stack.3d.up.fill")}.buttonStyle(.plain)
                }.listRowInsets(EdgeInsets()) }
                if !model.personalMixes.isEmpty { Section(L10n.Collection.personalMixes) { ForEach(model.personalMixes) { mix in NavigationLink { PersonalMixDetailView(model: PersonalMixDetailViewModel(mix: mix)) } label: { personalRow(mix) } } } }
                Section {
                    if model.inventory.isEmpty { Label(L10n.Inventory.empty,systemImage:"shippingbox").foregroundStyle(.secondary) }
                    ForEach(model.inventory.prefix(5)) { item in InventoryRow(item:item,isExpanded:model.expandedItemID==item.id) {
                        withAnimation(.snappy) { model.toggleExpanded(item.id) }
                    } select: { level in withAnimation(.snappy) { model.setLevel(level,itemID:item.id) } } }
                    Button(L10n.Inventory.add,systemImage:"plus"){model.showAddInventory=true}
                    NavigationLink(L10n.Common.all,value:CollectionSection.inventory)
                } header:{Text(L10n.Inventory.title)} footer:{Text(L10n.Inventory.hint)}
                Section { NavigationLink(L10n.Inventory.findMixes) { InventoryMixResultsView(model: makeMatches()) } }
                if model.isAdmin { Section(L10n.Admin.serviceSection) { Button { model.showAdmin=true } label:{
                    HStack(spacing:12){Image(systemName:"wrench.and.screwdriver.fill").foregroundStyle(AppTheme.gold).frame(width:28);VStack(alignment:.leading,spacing:3){Text(L10n.Admin.title).font(.body.weight(.medium));Text(L10n.Admin.serviceHint).font(.caption).foregroundStyle(.secondary)};Spacer();Image(systemName:"chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)}
                }.buttonStyle(.plain).accessibilityIdentifier("admin.entry").accessibilityHint(Text(L10n.Admin.serviceHint)) } }
            }
            .navigationTitle(L10n.Tab.collection).appScreenBackground()
            .alert(L10n.Content.Error.title,isPresented:Binding(get:{model.errorMessage != nil},set:{if !$0{model.clearError()}})){Button(L10n.Common.close){model.clearError()}}message:{Text(model.errorMessage ?? "")}
            .sheet(isPresented:$model.showAddInventory){InventoryAddView(model:model)}
            .toolbar { Button { model.showSettings=true } label:{Image(systemName:"person.crop.circle")}.accessibilityLabel(Text(L10n.Account.settings)) }
            .confirmationDialog(L10n.Account.settings,isPresented:$model.showSettings){Button(L10n.Account.logout){model.logout()};Button(L10n.Account.delete,role:.destructive){model.confirmDelete=true};Button(L10n.Common.cancel,role:.cancel){}}
            .sheet(isPresented:$model.showAdmin){adminView()}
            .alert(L10n.Account.Delete.confirm,isPresented:$model.confirmDelete){Button(L10n.Account.delete,role:.destructive){model.deleteAccount()};Button(L10n.Common.cancel,role:.cancel){}}message:{Text(L10n.Account.Delete.message)}
            .alert(L10n.Account.Delete.ProviderUnavailable.title,isPresented:$model.showProviderUnavailable){Button(L10n.Common.close){} }message:{Text(L10n.Account.Delete.ProviderUnavailable.message)}
            .navigationDestination(for:MixPreview.self){MixDetailView(model:makeMixDetail($0))}
            .navigationDestination(isPresented:Binding(get:{navigation.collectionDestination == .inventoryResults},set:{if !$0{navigation.collectionDestination=nil}})){InventoryMixResultsView(model:makeMatches())}
            .navigationDestination(for:CollectionSection.self){section in switch section{case .favorites:MixCollectionGrid(mixes:model.favoriteMixes,title:L10n.Collection.favorites);case .personal:PersonalMixList(mixes:model.personalMixes);case .inventory:InventoryFullList(model:model)}}
        }
    }

    private func counter(title:String,value:String,icon:String)->some View { VStack(alignment:.leading,spacing:6){Image(systemName:icon).foregroundStyle(AppTheme.gold);Text(value).font(.title2.bold());Text(title).font(.caption).foregroundStyle(.secondary)}.frame(maxWidth:.infinity,alignment:.leading).padding(14).background(AppTheme.card,in:RoundedRectangle(cornerRadius:18)) }
    private func personalRow(_ mix:PersonalMixRecord)->some View { HStack(spacing:12){PersonalMixArtwork(mix:mix).frame(width:52,height:52);VStack(alignment:.leading,spacing:5){Text(mix.title ?? L10n.Collection.untitledMix).font(.headline);Text(L10n.Collection.componentsLld(mix.components.count)).font(.caption).foregroundStyle(.secondary);if mix.isApproximate == true{Text(L10n.PersonalMix.approximate).font(.caption2).foregroundStyle(AppTheme.gold)}}} }
}

private struct SignedOutCollectionView:View {
    @ObservedObject var model:CollectionViewModel
    var body:some View { NavigationStack { List { placeholder(L10n.Collection.personalMixes,action:.personal);placeholder(L10n.Inventory.title,action:.inventory);placeholder(L10n.Collection.favorites,action:.favorite) }.navigationTitle(L10n.Tab.collection).appScreenBackground() }.accessibilityIdentifier("screen.mySignedOut") }
    private func placeholder(_ title:String,action:ProtectedAction)->some View { Section(title) { Button { model.requestAccess(action) {} } label:{ HStack { RoundedRectangle(cornerRadius:8).fill(.secondary.opacity(0.12)).frame(width:42,height:42);VStack(alignment:.leading){RoundedRectangle(cornerRadius:3).fill(.secondary.opacity(0.16)).frame(height:12);RoundedRectangle(cornerRadius:3).fill(.secondary.opacity(0.1)).frame(width:120,height:9)} }.redacted(reason:.placeholder) }.buttonStyle(.plain) } }
}

private enum CollectionSection:Hashable{case favorites,personal,inventory}
private struct MixCollectionGrid:View{let mixes:[MixPreview];let title:String;let columns=[GridItem(.flexible()),GridItem(.flexible())];var body:some View{ScrollView{LazyVGrid(columns:columns,spacing:10){ForEach(mixes){mix in NavigationLink(value:mix){MixCardView(mix:mix)}.buttonStyle(.plain)}}.padding()}.background(AppTheme.background).navigationTitle(title)}}
private struct PersonalMixList:View{let mixes:[PersonalMixRecord];var body:some View{List(mixes){mix in NavigationLink { PersonalMixDetailView(model: PersonalMixDetailViewModel(mix: mix)) } label: { HStack(spacing:12){PersonalMixArtwork(mix:mix).frame(width:58,height:58);VStack(alignment:.leading,spacing:4){Text(mix.title ?? L10n.Collection.untitledMix);Text(L10n.Collection.componentsLld(mix.components.count)).font(.caption).foregroundStyle(.secondary);if mix.isApproximate == true{Label(L10n.PersonalMix.approximate,systemImage:"approximately").font(.caption2).foregroundStyle(AppTheme.gold)}}} }.listRowBackground(AppTheme.card)}.navigationTitle(L10n.Collection.personalMixes).appScreenBackground()}}
