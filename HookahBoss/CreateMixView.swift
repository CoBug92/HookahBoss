import SwiftUI

struct CreateMixView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthRuntime
    @ObservedObject var store: PersonalMixStore
    @ObservedObject var inventory: InventoryStore
    @State private var title = ""
    @State private var components: [DraftComponent] = []
    @State private var isPickerPresented = false
    @State private var showValidation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    TextField("create.title.placeholder", text: $title)
                        .font(.title2.weight(.semibold))
                        .padding(16)
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("create.composition").font(.title2.weight(.semibold))
                        if components.isEmpty { firstComponent }
                        else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 12) {
                                    ForEach(Array(components.enumerated()), id: \.element.id) { index, component in
                                        DraftComponentCard(
                                            component: component,
                                            percentageText: $components[index].percentageText,
                                            effectivePercentage: effectivePercentage(at: index),
                                            isAutomatic: automaticIndices.contains(index),
                                            canMoveLeft: index > 0,
                                            canMoveRight: index < components.count - 1,
                                            onDelete: { components.remove(at: index) },
                                            onMoveLeft: { components.swapAt(index, index - 1) },
                                            onMoveRight: { components.swapAt(index, index + 1) }
                                        )
                                    }
                                    addCard
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    if showValidation, let message = validationMessage {
                        Label(message, systemImage: "exclamationmark.circle.fill")
                            .font(.subheadline).foregroundStyle(.red)
                    }
                }
                .padding(20)
            }
            .navigationTitle("create.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("common.save") { save() }.fontWeight(.semibold) }
            }
            .sheet(isPresented: $isPickerPresented) {
                ComponentPicker(excluding: Set(components.map(\.optionKey)), cachedInventory: inventory.items) { option in
                    components.append(DraftComponent(option: option))
                }
            }
            .task { await store.configure(client:auth.authorizedClient) }
            .alert("content.error.title",isPresented:Binding(get:{store.syncError != nil},set:{if !$0{store.syncError=nil}})){Button("common.close"){store.syncError=nil}} message:{Text(store.syncError ?? "")}
            .background(AppTheme.background)
        }
    }

    private var firstComponent: some View {
        Button { isPickerPresented = true } label: {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill").font(.system(size: 34)).foregroundStyle(AppTheme.gold)
                Text("create.firstComponent").font(.headline)
                Text("create.firstComponent.hint").font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 170)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 22))
        }.buttonStyle(.plain)
    }

    private var addCard: some View {
        Button { isPickerPresented = true } label: {
            VStack(spacing: 8) { Image(systemName: "plus").font(.title2); Text("create.add").font(.caption.weight(.semibold)) }
                .foregroundStyle(AppTheme.gold).frame(width: 112, height: 180)
                .background(AppTheme.gold.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(.plain)
    }

    private var enteredPercentages: [Int?] { components.map { Int($0.percentageText) } }
    private var distribution: PercentageValidation { PercentageDistributor.validate(enteredPercentages) }
    private var automaticIndices: Set<Int> { if case .valid(_, let automatic) = distribution { automatic } else { [] } }
    private func effectivePercentage(at index: Int) -> Int? { if case .valid(let values, _) = distribution { return values[index] }; return enteredPercentages[index] }
    private var validationMessage: LocalizedStringKey? {
        switch distribution {
        case .noComponents: "create.error.component"
        case .exceeds100: "create.error.over100"
        case .percentagesMustTotal100: "create.error.total100"
        case .insufficientRemainder: "create.error.remainder"
        case .valid: nil
        }
    }

    private func save() {
        guard case .valid(let effective, _) = distribution else { showValidation = true; return }
        let records = components.enumerated().map { index, draft in
            PersonalMixComponentRecord(id: UUID(), source: draft.option.source, sourceID: draft.option.sourceID,
                brand: draft.option.brand, line: draft.option.line, flavor: draft.option.flavor,
                percentage: effective[index], flavorProfiles: draft.option.flavorProfiles)
        }
        let record=PersonalMixRecord(id: UUID(), title: title.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,components:records,createdAt:Date(),isApproximate:automaticIndices.count == components.count)
        Task { if await store.addSynced(record) { dismiss() } }
    }
}

private struct DraftComponent: Identifiable {
    let id = UUID(); let option: ComponentOption; var percentageText = ""
    var optionKey: String { option.id }
}

private struct DraftComponentCard: View {
    let component: DraftComponent; @Binding var percentageText: String
    let effectivePercentage: Int?; let isAutomatic: Bool
    let canMoveLeft: Bool; let canMoveRight: Bool
    let onDelete: () -> Void; let onMoveLeft: () -> Void; let onMoveRight: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(component.option.source.title).font(.caption2).foregroundStyle(.secondary)
                Spacer(); Button(action: onDelete) { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary).frame(width:44,height:44) }.buttonStyle(.plain).accessibilityLabel(Text("common.delete"))
            }
            Text(component.option.flavor).font(.headline).lineLimit(2)
            Text(component.option.brandAndLine).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            Spacer()
            HStack(spacing: 5) {
                TextField("—", text: $percentageText)
                    .keyboardType(.numberPad).textFieldStyle(.roundedBorder).frame(width: 52)
                Text("%")
                if isAutomatic, let effectivePercentage { Text("create.auto \(effectivePercentage)").font(.caption2).foregroundStyle(AppTheme.gold) }
            }
        }
        .padding(12).frame(width: 150).frame(minHeight: 180)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
        .contextMenu {
            Button("create.moveLeft", systemImage: "arrow.left", action: onMoveLeft).disabled(!canMoveLeft)
            Button("create.moveRight", systemImage: "arrow.right", action: onMoveRight).disabled(!canMoveRight)
            Button("common.delete", systemImage: "trash", role: .destructive, action: onDelete)
        }
    }
}

private struct ComponentOption: Identifiable, Hashable {
    let source: ComponentSource; let sourceID: String; let brand: String?; let line: String?; let flavor: String; let flavorProfiles:[String]
    var id: String { "\(source.rawValue):\(sourceID)" }
    var brandAndLine: String { [brand, line].compactMap { $0 }.joined(separator: " · ") }
}

private extension ComponentSource {
    var title: String { String(localized: String.LocalizationValue("create.source.\(rawValue)")) }
}

private struct ComponentPicker: View {
    @EnvironmentObject private var auth:AuthRuntime
    @Environment(\.dismiss) private var dismiss
    let excluding: Set<String>; let cachedInventory: [InventoryItem]
    let select: (ComponentOption) -> Void
    @State private var source: ComponentSource = .catalog
    @State private var search = ""
    @StateObject private var content=PublicContentStore()
    @State private var remotePrivate:[PrivateProductDTO]=[]

    var body: some View {
        NavigationStack {
            List(filtered) { option in
                Button { select(option); dismiss() } label: {
                    VStack(alignment: .leading, spacing: 3) { Text(option.flavor).foregroundStyle(.primary); Text(option.brandAndLine).font(.caption).foregroundStyle(.secondary) }
                }
            }
            .searchable(text: $search, prompt: "create.search")
            .appScreenBackground()
            .safeAreaInset(edge: .top) { Picker("create.source", selection: $source) { ForEach(ComponentSource.allCases, id: \.self) { Text($0.title).tag($0) } }.pickerStyle(.segmented).padding(.horizontal).background(.bar) }
            .navigationTitle("create.choose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("common.close") { dismiss() } } }
            .task { await content.load(locale:.currentApp);async let privateProducts=auth.authorizedClient?.privateProducts();remotePrivate=(try? await privateProducts) ?? [] }
        }
    }

    private var filtered: [ComponentOption] {
        options.filter { option in !excluding.contains(option.id) && (search.isEmpty || (option.flavor + " " + option.brandAndLine).localizedCaseInsensitiveContains(search)) }
    }
    private var options: [ComponentOption] {
        switch source {
        case .catalog:
            return content.products.map{ComponentOption(source:.catalog,sourceID:$0.id.uuidString,brand:$0.brandName,line:$0.lineName,flavor:$0.name,flavorProfiles:$0.tags.map(\.profile))}
        case .personal:
            let cached=cachedInventory.filter{$0.id.hasPrefix("private:")}.map{ComponentOption(source:.personal,sourceID:$0.id,brand:$0.brand,line:$0.line,flavor:$0.flavor,flavorProfiles:$0.flavorProfiles ?? [])}
            let remote=remotePrivate.map{ComponentOption(source:.personal,sourceID:"private:\($0.id.uuidString)",brand:$0.brandName,line:$0.lineName,flavor:$0.flavorName,flavorProfiles:$0.flavorProfiles)}
            return Dictionary((cached+remote).map{($0.id,$0)},uniquingKeysWith:{_,new in new}).values.sorted{$0.flavor<$1.flavor}
        case .inventory:
            return cachedInventory.filter{$0.level != .empty}.map{item in ComponentOption(source:.inventory,sourceID:item.id,brand:item.brand,line:item.line,flavor:item.flavor,flavorProfiles:item.flavorProfiles ?? [])}
        }
    }
}

private extension String { var nilIfEmpty: String? { isEmpty ? nil : self } }
