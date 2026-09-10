import SwiftUI
struct PersonalMixArtwork:View {
    let mix:PersonalMixRecord
    private var profiles:[String]{Array(Set(mix.components.flatMap{$0.flavorProfiles ?? []})).sorted()}
    private var colors:[Color]{let mapped=profiles.prefix(3).map(Self.color);return mapped.isEmpty ? [AppTheme.gold,.orange] : mapped}
    var body:some View{ZStack{LinearGradient(colors:colors,startPoint:.topLeading,endPoint:.bottomTrailing);Circle().fill(.white.opacity(0.22)).frame(width:42).offset(x:18,y:-15);Circle().fill(.black.opacity(0.16)).frame(width:48).offset(x:-20,y:22)}.clipShape(RoundedRectangle(cornerRadius:16,style:.continuous)).accessibilityHidden(true)}
    static func color(_ profile:String)->Color{switch profile{case "berry":.pink;case "fruit":.orange;case "citrus":.yellow;case "dessert":.brown;case "beverage":.cyan;case "herbal":.green;case "spicy":.red;case "fresh":.cyan;default:AppTheme.gold}}
}
struct InventoryFullList:View{@ObservedObject var model:CollectionViewModel;var body:some View{List(model.inventory){item in InventoryRow(item:item,isExpanded:model.expandedItemID==item.id){model.toggleExpanded(item.id)}select:{model.setLevel($0,itemID:item.id)}.swipeActions{if item.id.hasPrefix("private:"){Button(L10n.Common.delete,role:.destructive){model.deletePrivate(item)}}}.listRowBackground(AppTheme.card)}.navigationTitle(L10n.Inventory.title).appScreenBackground()}}

struct InventoryAddView:View {
    @Environment(\.dismiss)private var dismiss;@ObservedObject var model:CollectionViewModel
    @State private var search="";@State private var showPrivate=false
    var body:some View{NavigationStack{List(filtered){product in Button{model.add(product);dismiss()}label:{VStack(alignment:.leading){Text(product.name);Text("\(product.brandName) · \(product.lineName)").font(.caption).foregroundStyle(.secondary)}}.listRowBackground(AppTheme.card)}.searchable(text:$search,prompt:L10n.Create.search).navigationTitle(L10n.Inventory.add).appScreenBackground().toolbar{ToolbarItem(placement:.topBarLeading){Button(L10n.Common.close){dismiss()}};ToolbarItem(placement:.topBarTrailing){Button(L10n.Inventory.addPrivate){showPrivate=true}}}.sheet(isPresented:$showPrivate){PrivateProductAddView(model:model)}}}
    private var filtered:[TobaccoProductDTO]{model.products.filter{search.isEmpty || ($0.name+" "+$0.brandName+" "+$0.lineName).localizedCaseInsensitiveContains(search)}}
}
private struct PrivateProductAddView:View {
    @Environment(\.dismiss)private var dismiss;@ObservedObject var model:CollectionViewModel
    @State private var brand=""
    @State private var line=""
    @State private var flavor=""
    @State private var profiles:Set<FlavorProfile>=[]
    @State private var error=false
    var body:some View{NavigationStack{Form{TextField(L10n.Inventory.Private.brand,text:$brand);TextField(L10n.Inventory.Private.line,text:$line);TextField(L10n.Inventory.Private.flavor,text:$flavor);Section(L10n.Filters.profiles){ForEach(FlavorProfile.allCases){profile in Toggle(profile.title,isOn:profileBinding(profile))}}}.navigationTitle(L10n.Inventory.addPrivate).appScreenBackground().toolbar{ToolbarItem(placement:.cancellationAction){Button(L10n.Common.cancel){dismiss()}};ToolbarItem(placement:.confirmationAction){Button(L10n.Common.save,action:save).disabled(brand.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || flavor.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)}}.alert(L10n.Content.Error.title,isPresented:$error){Button(L10n.Common.close){} }}}
    private func profileBinding(_ profile:FlavorProfile)->Binding<Bool>{Binding(get:{profiles.contains(profile)},set:{selected in if selected{profiles.insert(profile)}else{profiles.remove(profile)}})}
    private func save(){let trimmed=line.trimmingCharacters(in:.whitespacesAndNewlines);model.createPrivate(brand:brand,line:trimmed.isEmpty ? nil:trimmed,flavor:flavor,profiles:profiles.map(\.rawValue)){succeeded in if succeeded{dismiss()}else{error=true}}}
}

struct InventoryRow: View {
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
            .accessibilityHint(Text(isExpanded ? L10n.Inventory.Accessibility.collapse:L10n.Inventory.Accessibility.expand))

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
                        .accessibilityValue(Text(item.level == level ? L10n.Accessibility.selected:L10n.Accessibility.notSelected))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
}

struct InventoryMixResultsView: View {
    @StateObject private var model: InventoryMatchViewModel
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    init(model: @autoclosure @escaping () -> InventoryMatchViewModel) {
        _model = StateObject(wrappedValue: model())
    }

    var body: some View {
        ScrollView {
            if model.state == .loading {
                ProgressView().padding(.top, 80)
            } else if model.state == .failed {
                ContentUnavailableView(L10n.Content.Error.title, systemImage: "wifi.exclamationmark", description: Text(L10n.Content.Error.network))
                    .padding(.top, 80)
            } else if model.isEmpty {
                ContentUnavailableView(L10n.Inventory.Results.Empty.title, systemImage: "shippingbox", description: Text(L10n.Inventory.Results.Empty.message))
                    .padding(.top, 80)
            } else {
                LazyVStack(alignment: .leading, spacing: 24) {
                    resultSection(title: L10n.Inventory.Results.ready, results: model.ready)
                    resultSection(title: L10n.Inventory.Results.substitution, results: model.substitutions)
                    resultSection(title: L10n.Inventory.Results.missing, results: model.missing)
                }
                .padding(16)
            }
        }
        .background(AppTheme.background)
        .navigationTitle(L10n.Inventory.Results.title)
        .onAppear { model.appear() }
    }

    @ViewBuilder private func resultSection(title: String, results: [InventoryMixResult]) -> some View {
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

}
