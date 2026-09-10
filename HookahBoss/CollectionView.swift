import SwiftUI

enum InventoryLevel: String, CaseIterable, Codable, Identifiable {
    case plenty, low, empty

    var id: String { rawValue }
    var title: String { String(localized: String.LocalizationValue("inventory.level.\(rawValue)")) }
    var color: Color {
        switch self {
        case .plenty: .green
        case .low: .orange
        case .empty: .secondary
        }
    }
}

struct InventoryItem: Identifiable, Codable, Hashable {
    let id: String
    let brand: String
    let line: String?
    let flavor: String
    var level: InventoryLevel
    var flavorProfiles: [String]? = nil

    var brandAndLine: String { [brand, line].compactMap { $0 }.joined(separator: " · ") }
}

@MainActor
final class InventoryStore: ObservableObject {
    @Published private(set) var items: [InventoryItem] { didSet { save() } }
    private let storageKey: String?
    private let outboxKey:String?
    private let privateOutboxKey:String?
    private var client: APIClient?
    @Published var syncError: String?

    init(defaults: UserDefaults = .standard, accountId: UUID? = nil) {
        AccountCache.discardLegacy(defaults:defaults);storageKey=accountId.map { AccountCache.key("inventory.v1",accountId:$0) };outboxKey=accountId.map{AccountCache.key("inventory.outbox.v1",accountId:$0)};privateOutboxKey=accountId.map{AccountCache.key("private.outbox.v1",accountId:$0)}
        if let storageKey,let data = defaults.data(forKey: storageKey), let saved = try? JSONDecoder().decode([InventoryItem].self, from: data) {
            items = saved
        } else if accountId != nil {
            items = []
        } else { items=[] }
        self.defaults = defaults
    }

    func setLevel(_ level: InventoryLevel, for id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let old=items[index].level
        items[index].level = level
        guard let client else{return};let isPrivate=id.hasPrefix("private:"),raw=isPrivate ? String(id.dropFirst(8)):id;guard let productId=UUID(uuidString:raw)else{return}
        Task { do { _ = try await client.upsertInventory(.init(productId:isPrivate ? nil:productId,privateProductId:isPrivate ? productId:nil,level:level.rawValue)) } catch { if error.isRetryableSyncFailure { self.enqueue(.init(productId:isPrivate ? nil:productId,privateProductId:isPrivate ? productId:nil,level:level)) } else if let current=self.items.firstIndex(where:{$0.id==id}) { self.items[current].level=old };self.syncError=String(localized:"content.error.network") } }
    }

    func bootstrap(from products: [TobaccoProductDTO]) {
        guard items.isEmpty else { return }
    }
    func configure(client:APIClient?,products:[TobaccoProductDTO]) async {
        self.client=client;await replayPrivateOutbox();await replayOutbox()
        let productMap=Dictionary(uniqueKeysWithValues:products.map{($0.id,$0)});let saved=items
        items=saved.compactMap{item in guard let id=UUID(uuidString:item.id),let product=productMap[id] else{return item.id.hasPrefix("private:") ? item:nil};return InventoryItem(id:item.id,brand:product.brandName,line:product.lineName,flavor:product.name,level:item.level,flavorProfiles:product.tags.map(\.profile))}
        guard let remote=try? await client?.inventory() else{return}
        for dto in remote {guard let level=InventoryLevel(rawValue:dto.level)else{continue};let id=dto.productId?.uuidString ?? dto.privateProductId.map{"private:\($0.uuidString)"};guard let id else{continue};let profiles=items.first(where:{$0.id==id})?.flavorProfiles;let value=InventoryItem(id:id,brand:dto.brandName ?? "",line:dto.lineName,flavor:dto.flavorName ?? "",level:level,flavorProfiles:profiles);if let index=items.firstIndex(where:{$0.id==id}){items[index]=value}else{items.append(value)}}
        let pairs:[(UUID,InventoryLevel)]=remote.compactMap{dto in guard let id=dto.productId,let level=InventoryLevel(rawValue:dto.level)else{return nil};return(id,level)}
        let remoteLevels:[UUID:InventoryLevel]=Dictionary(uniqueKeysWithValues:pairs)
        let effective=InventoryProjection.overlay(levels:remoteLevels,pending:pendingMutations())
        for (id,level) in effective {if let index=items.firstIndex(where:{$0.id==id.uuidString}){items[index].level=level}}
    }
    func add(_ product:TobaccoProductDTO){guard !items.contains(where:{$0.id==product.id.uuidString})else{return};items.append(.init(id:product.id.uuidString,brand:product.brandName,line:product.lineName,flavor:product.name,level:.plenty,flavorProfiles:product.tags.map(\.profile)));setLevel(.plenty,for:product.id.uuidString)}
    func addPrivate(_ product:PrivateProductDTO){let id="private:\(product.id.uuidString)";guard !items.contains(where:{$0.id==id})else{return};items.append(.init(id:id,brand:product.brandName,line:product.lineName,flavor:product.flavorName,level:.plenty,flavorProfiles:product.flavorProfiles));setLevel(.plenty,for:id)}
    func createPrivate(brand:String,line:String?,flavor:String,profiles:[String])async->Bool{let id=UUID(),input=PrivateProductWrite(clientId:id,brandName:brand,lineName:line,flavorName:flavor,flavorProfiles:profiles);let local=PrivateProductDTO(id:id,brandName:brand,lineName:line,flavorName:flavor,flavorProfiles:profiles,createdAt:ISO8601DateFormatter().string(from:Date()));addPrivate(local);guard let client else{enqueuePrivate(input);return true};do{_ = try await client.createPrivateProduct(input);return true}catch{if error.isRetryableSyncFailure{enqueuePrivate(input);return true};items.removeAll{$0.id=="private:\(id.uuidString)"};syncError=String(localized:"content.error.network");return false}}
    func deletePrivate(_ item:InventoryItem){guard item.id.hasPrefix("private:"),let id=UUID(uuidString:String(item.id.dropFirst(8))),let client else{return};let index=items.firstIndex(where:{$0.id==item.id});if let index{items.remove(at:index)};Task{do{try await client.deletePrivateProduct(id:id)}catch{if let index{items.insert(item,at:min(index,items.count))};syncError=String(localized:"content.error.network")}}}
    private func enqueue(_ mutation:InventoryMutation){guard let outboxKey else{return};let queue=(defaults.data(forKey:outboxKey).flatMap{try? JSONDecoder().decode([InventoryMutation].self,from:$0)}) ?? [];defaults.set(try? JSONEncoder().encode(OutboxQueue.upserting(mutation,in:queue){$0.key==$1.key}),forKey:outboxKey)}
    private func pendingMutations()->[InventoryMutation]{guard let outboxKey else{return []};return defaults.data(forKey:outboxKey).flatMap{try? JSONDecoder().decode([InventoryMutation].self,from:$0)} ?? []}
    private func replayOutbox() async {guard let client,let outboxKey,var queue=defaults.data(forKey:outboxKey).flatMap({try? JSONDecoder().decode([InventoryMutation].self,from:$0)}) else{return};for mutation in queue { do {_ = try await client.upsertInventory(.init(productId:mutation.productId,privateProductId:mutation.privateProductId,level:mutation.level.rawValue));queue.removeAll{$0.key==mutation.key}}catch{if error.isRetryableSyncFailure{break}else{queue.removeAll{$0.key==mutation.key}}} };defaults.set(try? JSONEncoder().encode(queue),forKey:outboxKey)}
    private func enqueuePrivate(_ input:PrivateProductWrite){guard let key=privateOutboxKey else{return};var queue=(defaults.data(forKey:key).flatMap{try? JSONDecoder().decode([PrivateProductWrite].self,from:$0)}) ?? [];queue.removeAll{$0.clientId==input.clientId};queue.append(input);defaults.set(try? JSONEncoder().encode(queue),forKey:key)}
    private func replayPrivateOutbox()async{guard let client,let key=privateOutboxKey,var queue=defaults.data(forKey:key).flatMap({try? JSONDecoder().decode([PrivateProductWrite].self,from:$0)})else{return};for input in queue{do{_ = try await client.createPrivateProduct(input);queue.removeAll{$0.clientId==input.clientId}}catch{if error.isRetryableSyncFailure{break}else{queue.removeAll{$0.clientId==input.clientId}}}};defaults.set(try? JSONEncoder().encode(queue),forKey:key)}

    private let defaults: UserDefaults
    private func save() {
        guard let storageKey,let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: storageKey)
    }

}

struct CollectionView: View {
    @EnvironmentObject private var auth: AuthRuntime
    @ObservedObject var workspace: AccountWorkspace
    var body: some View {
        Group { if let stores=workspace.current { AccountCollectionView(inventory:stores.inventory,personalMixes:stores.personalMixes) } else { SignedOutCollectionView() } }
            .onAppear { if !auth.isAuthenticated { auth.gate.request(.inventory) {} } }
    }
}

private struct SignedOutCollectionView:View {
    @EnvironmentObject private var auth:AuthRuntime
    var body:some View { NavigationStack { List { placeholder("collection.personalMixes",action:.personal);placeholder("inventory.title",action:.inventory);placeholder("favorite.title",action:.favorite) }.navigationTitle("tab.collection").appScreenBackground() }.accessibilityIdentifier("screen.mySignedOut") }
    private func placeholder(_ title:LocalizedStringKey,action:ProtectedAction)->some View { Section(title) { Button { auth.gate.request(action) {} } label:{ HStack { RoundedRectangle(cornerRadius:8).fill(.secondary.opacity(0.12)).frame(width:42,height:42);VStack(alignment:.leading){RoundedRectangle(cornerRadius:3).fill(.secondary.opacity(0.16)).frame(height:12);RoundedRectangle(cornerRadius:3).fill(.secondary.opacity(0.1)).frame(width:120,height:9)} }.redacted(reason:.placeholder) }.buttonStyle(.plain) } }
}

private struct AccountCollectionView: View {
    @EnvironmentObject private var auth:AuthRuntime
    @EnvironmentObject private var navigation:AppNavigation
    @ObservedObject var inventory: InventoryStore
    @ObservedObject var personalMixes: PersonalMixStore
    @State private var expandedItemID: String?
    @State private var showSettings=false
    @State private var showAdmin=false
    @State private var confirmDelete=false
    @State private var showProviderUnavailable=false
    @State private var showAddInventory=false
    @StateObject private var content = PublicContentStore()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing:12) {
                        NavigationLink(value:CollectionSection.favorites){collectionCounter(title:"favorite.title", value: String(auth.favoriteMixIDs.count), icon:"heart.fill")}.buttonStyle(.plain)
                        NavigationLink(value:CollectionSection.personal){collectionCounter(title:"collection.personalMixes", value: String(personalMixes.mixes.count), icon:"square.stack.3d.up.fill")}.buttonStyle(.plain)
                    }.listRowInsets(EdgeInsets())
                }
                if !personalMixes.mixes.isEmpty {
                    Section("collection.personalMixes") {
                        ForEach(personalMixes.mixes) { mix in
                            HStack(spacing:12) {
                                PersonalMixArtwork(mix:mix).frame(width:52,height:52)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(mix.title ?? String(localized: "collection.untitledMix")).font(.headline)
                                    Text("collection.components \(mix.components.count)").font(.caption).foregroundStyle(.secondary)
                                    if mix.isApproximate == true { Text("personalMix.approximate").font(.caption2).foregroundStyle(AppTheme.gold) }
                                }
                            }
                        }
                    }
                }
                Section {
                    if inventory.items.isEmpty {
                        Label("inventory.empty", systemImage: "shippingbox")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(inventory.items.prefix(5)) { item in
                        InventoryRow(item: item, isExpanded: expandedItemID == item.id) {
                            withAnimation(.snappy) { expandedItemID = expandedItemID == item.id ? nil : item.id }
                        } select: { level in
                            inventory.setLevel(level, for: item.id)
                            withAnimation(.snappy) { expandedItemID = nil }
                        }
                    }
                    Button("inventory.add",systemImage:"plus"){showAddInventory=true}
                    NavigationLink("common.all",value:CollectionSection.inventory)
                } header: {
                    Text("inventory.title")
                } footer: {
                    Text("inventory.hint")
                }

                Section {
                    NavigationLink("inventory.findMixes") {
                        InventoryMixResultsView(inventory: inventory.items, catalog: content.mixes, products: content.products)
                    }
                }
                if AdminEntryVisibility.isVisible(isAuthenticated:auth.isAuthenticated,isAdmin:auth.isAdmin) {
                    Section("admin.serviceSection") {
                        Button { showAdmin=true } label:{HStack(spacing:12){Image(systemName:"wrench.and.screwdriver.fill").foregroundStyle(AppTheme.gold).frame(width:28);VStack(alignment:.leading,spacing:3){Text("admin.title").font(.body.weight(.medium));Text("admin.serviceHint").font(.caption).foregroundStyle(.secondary)};Spacer();Image(systemName:"chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)}}
                            .buttonStyle(.plain).accessibilityIdentifier("admin.entry").accessibilityHint(Text("admin.serviceHint"))
                    }
                }
            }
            .navigationTitle("tab.collection")
            .appScreenBackground()
            .task { await content.load(locale:.currentApp); await inventory.configure(client:auth.authorizedClient,products:content.products);await personalMixes.configure(client:auth.authorizedClient) }
            .alert("content.error.title",isPresented:Binding(get:{inventory.syncError != nil},set:{if !$0{inventory.syncError=nil}})){Button("common.close"){inventory.syncError=nil}} message:{Text(inventory.syncError ?? "")}
            .alert("content.error.title",isPresented:Binding(get:{auth.libraryError != nil},set:{if !$0{auth.libraryError=nil}})){Button("common.close"){auth.libraryError=nil}} message:{Text(auth.libraryError ?? "")}
            .sheet(isPresented:$showAddInventory){InventoryAddView(products:content.products,inventory:inventory,client:auth.authorizedClient)}
            .toolbar { Button { showSettings=true } label:{Image(systemName:"person.crop.circle")}.accessibilityLabel(Text("account.settings")) }
            .confirmationDialog("account.settings",isPresented:$showSettings){Button("account.logout"){Task{await auth.logout()}};Button("account.delete",role:.destructive){confirmDelete=true};Button("common.cancel",role:.cancel){}}
            .sheet(isPresented:$showAdmin){if auth.isAdmin,let client=auth.authorizedClient{AdminDashboardView(client:client)}}
            .alert("account.delete.confirm",isPresented:$confirmDelete){Button("account.delete",role:.destructive){Task{do{showProviderUnavailable=try await auth.deleteAccount()}catch{auth.libraryError=String(localized:"content.error.network")}}};Button("common.cancel",role:.cancel){}} message:{Text("account.delete.message")}
            .alert("account.delete.providerUnavailable.title",isPresented:$showProviderUnavailable){Button("common.close"){} }message:{Text("account.delete.providerUnavailable.message")}
            .navigationDestination(for: MixPreview.self) { mix in
                MixDetailView(mix: mix,content:content)
            }
            .navigationDestination(isPresented:Binding(get:{navigation.collectionDestination == .inventoryResults},set:{if !$0{navigation.collectionDestination=nil}})){InventoryMixResultsView(inventory:inventory.items,catalog:content.mixes,products:content.products)}
            .navigationDestination(for:CollectionSection.self){section in switch section{case .favorites:MixCollectionGrid(mixes:content.mixes.filter{auth.favoriteMixIDs.contains($0.id)},title:"favorite.title");case .personal:PersonalMixList(mixes:personalMixes.mixes);case .inventory:InventoryFullList(inventory:inventory)}}
        }
    }

    private func collectionCounter(title:LocalizedStringKey,value:String,icon:String)->some View { VStack(alignment:.leading,spacing:6){Image(systemName:icon).foregroundStyle(AppTheme.gold);Text(value).font(.title2.bold());Text(title).font(.caption).foregroundStyle(.secondary)}.frame(maxWidth:.infinity,alignment:.leading).padding(14).background(AppTheme.card,in:RoundedRectangle(cornerRadius:18)) }
}
enum AdminEntryVisibility { static func isVisible(isAuthenticated:Bool,isAdmin:Bool)->Bool { isAuthenticated && isAdmin } }
private enum CollectionSection:Hashable{case favorites,personal,inventory}
private struct MixCollectionGrid:View{let mixes:[MixPreview];let title:LocalizedStringKey;let columns=[GridItem(.flexible()),GridItem(.flexible())];var body:some View{ScrollView{LazyVGrid(columns:columns,spacing:10){ForEach(mixes){mix in NavigationLink(value:mix){MixCardView(mix:mix)}.buttonStyle(.plain)}}.padding()}.background(AppTheme.background).navigationTitle(title)}}
private struct PersonalMixList:View{let mixes:[PersonalMixRecord];var body:some View{List(mixes){mix in HStack(spacing:12){PersonalMixArtwork(mix:mix).frame(width:58,height:58);VStack(alignment:.leading,spacing:4){Text(mix.title ?? String(localized:"collection.untitledMix"));Text("collection.components \(mix.components.count)").font(.caption).foregroundStyle(.secondary);if mix.isApproximate == true{Label("personalMix.approximate",systemImage:"approximately").font(.caption2).foregroundStyle(AppTheme.gold)}}}.listRowBackground(AppTheme.card)}.navigationTitle("collection.personalMixes").appScreenBackground()}}

struct PersonalMixArtwork:View {
    let mix:PersonalMixRecord
    private var profiles:[String]{Array(Set(mix.components.flatMap{$0.flavorProfiles ?? []})).sorted()}
    private var colors:[Color]{let mapped=profiles.prefix(3).map(Self.color);return mapped.isEmpty ? [AppTheme.gold,.orange] : mapped}
    var body:some View{ZStack{LinearGradient(colors:colors,startPoint:.topLeading,endPoint:.bottomTrailing);Circle().fill(.white.opacity(0.22)).frame(width:42).offset(x:18,y:-15);Circle().fill(.black.opacity(0.16)).frame(width:48).offset(x:-20,y:22)}.clipShape(RoundedRectangle(cornerRadius:16,style:.continuous)).accessibilityHidden(true)}
    static func color(_ profile:String)->Color{switch profile{case "berry":.pink;case "fruit":.orange;case "citrus":.yellow;case "dessert":.brown;case "beverage":.cyan;case "herbal":.green;case "spicy":.red;case "fresh":.cyan;default:AppTheme.gold}}
}
private struct InventoryFullList:View{@ObservedObject var inventory:InventoryStore;@State private var expanded:String?;var body:some View{List(inventory.items){item in InventoryRow(item:item,isExpanded:expanded==item.id){expanded=expanded==item.id ? nil:item.id}select:{inventory.setLevel($0,for:item.id);expanded=nil}.swipeActions{if item.id.hasPrefix("private:"){Button("common.delete",role:.destructive){inventory.deletePrivate(item)}}}.listRowBackground(AppTheme.card)}.navigationTitle("inventory.title").appScreenBackground()}}

private struct InventoryAddView:View {
    @Environment(\.dismiss)private var dismiss;let products:[TobaccoProductDTO];@ObservedObject var inventory:InventoryStore;let client:APIClient?
    @State private var search="";@State private var showPrivate=false
    var body:some View{NavigationStack{List(filtered){product in Button{inventory.add(product);dismiss()}label:{VStack(alignment:.leading){Text(product.name);Text("\(product.brandName) · \(product.lineName)").font(.caption).foregroundStyle(.secondary)}}.listRowBackground(AppTheme.card)}.searchable(text:$search,prompt:"create.search").navigationTitle("inventory.add").appScreenBackground().toolbar{ToolbarItem(placement:.topBarLeading){Button("common.close"){dismiss()}};ToolbarItem(placement:.topBarTrailing){Button("inventory.addPrivate"){showPrivate=true}}}.sheet(isPresented:$showPrivate){PrivateProductAddView(inventory:inventory)}}}
    private var filtered:[TobaccoProductDTO]{products.filter{search.isEmpty || ($0.name+" "+$0.brandName+" "+$0.lineName).localizedCaseInsensitiveContains(search)}}
}
private struct PrivateProductAddView:View {
    @Environment(\.dismiss)private var dismiss;@ObservedObject var inventory:InventoryStore
    @State private var brand=""
    @State private var line=""
    @State private var flavor=""
    @State private var profiles:Set<FlavorProfile>=[]
    @State private var error=false
    var body:some View{NavigationStack{Form{TextField("inventory.private.brand",text:$brand);TextField("inventory.private.line",text:$line);TextField("inventory.private.flavor",text:$flavor);Section("filters.profiles"){ForEach(FlavorProfile.allCases){profile in Toggle(profile.title,isOn:profileBinding(profile))}}}.navigationTitle("inventory.addPrivate").appScreenBackground().toolbar{ToolbarItem(placement:.cancellationAction){Button("common.cancel"){dismiss()}};ToolbarItem(placement:.confirmationAction){Button("common.save",action:save).disabled(brand.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || flavor.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)}}.alert("content.error.title",isPresented:$error){Button("common.close"){} }}}
    private func profileBinding(_ profile:FlavorProfile)->Binding<Bool>{Binding(get:{profiles.contains(profile)},set:{selected in if selected{profiles.insert(profile)}else{profiles.remove(profile)}})}
    private func save(){Task{let trimmed=line.trimmingCharacters(in:.whitespacesAndNewlines);if await inventory.createPrivate(brand:brand,line:trimmed.isEmpty ? nil:trimmed,flavor:flavor,profiles:profiles.map(\.rawValue)){dismiss()}else{error=true}}}
}

private struct InventoryRow: View {
    let item: InventoryItem
    let isExpanded: Bool
    let toggle: () -> Void
    let select: (InventoryLevel) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: toggle) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.flavor).font(.headline)
                        Text(item.brandAndLine).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(item.level.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(item.level.color)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("\(item.flavor), \(item.brandAndLine)"))
            .accessibilityValue(Text(item.level.title))
            .accessibilityHint(Text(isExpanded ? "inventory.accessibility.collapse":"inventory.accessibility.expand"))

            if isExpanded {
                HStack(spacing: 8) {
                    ForEach(InventoryLevel.allCases) { level in
                        Button { select(level) } label: {
                            Text(level.title)
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .foregroundStyle(item.level == level ? Color.white : level.color)
                                .background(item.level == level ? level.color : level.color.opacity(0.11), in: RoundedRectangle(cornerRadius: 11))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(level.title))
                        .accessibilityValue(Text(item.level == level ? "accessibility.selected":"accessibility.notSelected"))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
}

private struct InventoryMixResultsView: View {
    @EnvironmentObject private var auth:AuthRuntime
    let inventory: [InventoryItem]
    let catalog: [MixPreview]
    let products: [TobaccoProductDTO]
    @State private var matchState: InventoryMatchLoadState = .loading
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        ScrollView {
            if case .loading = matchState {
                ProgressView().padding(.top, 80)
            } else if case .failed = matchState {
                ContentUnavailableView("content.error.title", systemImage: "wifi.exclamationmark", description: Text("content.error.network"))
                    .padding(.top, 80)
            } else if ready.isEmpty && substitutions.isEmpty && missing.isEmpty {
                ContentUnavailableView("inventory.results.empty.title", systemImage: "shippingbox", description: Text("inventory.results.empty.message"))
                    .padding(.top, 80)
            } else {
                LazyVStack(alignment: .leading, spacing: 24) {
                    resultSection(title: "inventory.results.ready", results: ready)
                    resultSection(title: "inventory.results.substitution", results: substitutions)
                    resultSection(title: "inventory.results.missing", results: missing)
                }
                .padding(16)
            }
        }
        .background(AppTheme.background)
        .navigationTitle("inventory.results.title")
        .task { await loadMatches() }
    }

    @ViewBuilder private func resultSection(title: LocalizedStringKey, results: [InventoryMixResult]) -> some View {
        if !results.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(.title2.weight(.semibold))
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(results) { result in
                        VStack(alignment: .leading, spacing: 7) {
                            NavigationLink(value: result.mix) { MixCardView(mix: result.mix) }.buttonStyle(.plain)
                            if let note = result.note {
                                Label(note, systemImage: result.kind == .substitution ? "arrow.right" : "minus.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
        }
    }

    private var ready: [InventoryMixResult] { classified.filter{$0.kind == .ready} }
    private var substitutions: [InventoryMixResult] { classified.filter{$0.kind == .substitution} }
    private var missing: [InventoryMixResult] { classified.filter{$0.kind == .missing} }
    private var productByID:[UUID:TobaccoProductDTO] { Dictionary(uniqueKeysWithValues:products.map{($0.id,$0)}) }
    private var classified:[InventoryMixResult] {
        guard case .loaded(let matches) = matchState else { return [] }
        return matches.compactMap { match in guard let mix=catalog.first(where:{$0.id==match.mixId}),let kind=InventoryMixResult.Kind(rawValue:match.kind) else{return nil};let note=kind == .missing ? match.missingFlavor : substitutionNote(match);return InventoryMixResult(mix:mix,kind:kind,note:note) }
    }
    private func substitutionNote(_ match:InventoryMatchDTO)->String? { guard let source=match.sourceProductId.flatMap({productByID[$0]}),let target=match.substituteProductId.flatMap({productByID[$0]}) else{return match.missingFlavor};return "\(source.name) → \(target.name)" }
    @MainActor private func loadMatches() async {
        guard let accountId=auth.accountId,let client=auth.authorizedClient else { matchState = .failed; return }
        do {
            let matches=try await client.inventoryMatches(locale:.currentApp)
            InventoryMatchCache.save(matches,accountId:accountId)
            matchState = .loaded(matches)
        } catch {
            matchState = InventoryMatchCache.load(accountId:accountId).map(InventoryMatchLoadState.loaded) ?? .failed
        }
    }
}

enum InventoryMatchLoadState: Equatable { case loading, loaded([InventoryMatchDTO]), failed }
enum InventoryMatchCache {
    private static let baseKey="inventory.matches.v1"
    static func save(_ matches:[InventoryMatchDTO],accountId:UUID,defaults:UserDefaults = .standard){defaults.set(try? JSONEncoder().encode(matches),forKey:AccountCache.key(baseKey,accountId:accountId))}
    static func load(accountId:UUID,defaults:UserDefaults = .standard)->[InventoryMatchDTO]?{guard let data=defaults.data(forKey:AccountCache.key(baseKey,accountId:accountId))else{return nil};return try? JSONDecoder().decode([InventoryMatchDTO].self,from:data)}
}

private struct InventoryMixResult: Identifiable {
    enum Kind:String,Equatable { case ready, substitution, missing }
    let mix: MixPreview
    let kind: Kind
    var note: String? = nil
    var id: UUID { mix.id }
}
