import SwiftUI

struct CreateMixView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: CreateMixViewModel
    @State private var isPickerPresented = false

    init(model: @autoclosure @escaping () -> CreateMixViewModel) { _model = StateObject(wrappedValue: model()) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Text(L10n.Create.title).font(.system(size:34,weight:.bold,design:.serif)).tracking(-0.7)
                    TextField(L10n.Create.Title.placeholder, text: $model.title).font(.title2.weight(.semibold)).padding(17).appCard(cornerRadius:18)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.Create.composition).font(.title2.weight(.semibold))
                        if model.components.isEmpty { firstComponent } else { componentStrip }
                    }
                    if model.showValidation, let message = model.validationMessage {
                        Label(message, systemImage: "exclamationmark.circle.fill").font(.subheadline).foregroundStyle(.red)
                    }
                }.padding(20)
            }
            .overlay { if model.isLoading { ProgressView() } }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.Common.cancel) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if model.isSaving { ProgressView() }
                    else { Button(L10n.Common.save) { model.save() }.fontWeight(.semibold).disabled(model.isLoading) }
                }
            }
            .sheet(isPresented: $isPickerPresented) {
                ComponentPicker(model: ComponentPickerViewModel(snapshot: model.options, excluding: Set(model.components.map(\.optionKey))), select: model.add)
            }
            .onAppear { model.appear() }
            .onChange(of: model.didSave) { _, saved in if saved { dismiss() } }
            .alert(L10n.Content.Error.title, isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.clearError() } })) {
                Button(L10n.Common.close) { model.clearError() }; Button(L10n.Common.retry) { model.retry() }
            } message: { Text(model.errorMessage ?? "") }
            .background(AppTheme.background)
        }
    }

    private var componentStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(Array(model.components.enumerated()), id: \.element.id) { index, component in
                    DraftComponentCard(component: component,
                        percentageText: Binding(get: { model.percentageBinding(at: index) }, set: { model.setPercentage($0, at: index) }),
                        effectivePercentage: model.effectivePercentage(at: index), isAutomatic: model.automaticIndices.contains(index),
                        canMoveLeft: index > 0, canMoveRight: index < model.components.count - 1,
                        onDelete: { model.delete(at: index) }, onMoveLeft: { model.moveLeft(from: index) }, onMoveRight: { model.moveRight(from: index) })
                }
                addCard
            }.padding(.vertical, 2)
        }
    }

    private var firstComponent: some View {
        Button { isPickerPresented = true } label: {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill").font(.system(size: 34)).foregroundStyle(AppTheme.gold)
                Text(L10n.Create.firstComponent).font(.headline)
                Text(L10n.Create.FirstComponent.hint).font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, minHeight: 170).appCard(cornerRadius:22)
        }.buttonStyle(.plain).disabled(model.isLoading)
    }

    private var addCard: some View {
        Button { isPickerPresented = true } label: {
            VStack(spacing: 8) { Image(systemName: "plus").font(.title2); Text(L10n.Create.add).font(.caption.weight(.semibold)) }
                .foregroundStyle(AppTheme.gold).frame(width: 112, height: 180)
                .background(AppTheme.gold.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(.plain).disabled(model.isLoading)
    }
}

private struct DraftComponentCard: View {
    let component: DraftComponent; @Binding var percentageText: String
    let effectivePercentage: Int?; let isAutomatic: Bool; let canMoveLeft: Bool; let canMoveRight: Bool
    let onDelete: () -> Void; let onMoveLeft: () -> Void; let onMoveRight: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text(component.option.source.title).font(.caption2).foregroundStyle(.secondary); Spacer()
                Button(action: onDelete) { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary).frame(width: 44, height: 44) }.buttonStyle(.plain).accessibilityLabel(Text(L10n.Common.delete)) }
            Text(component.option.flavor).font(.headline).lineLimit(2)
            Text(component.option.brandAndLine).font(.caption).foregroundStyle(.secondary).lineLimit(2); Spacer()
            HStack(spacing: 5) {
                TextField("—", text: $percentageText).keyboardType(.numberPad).textFieldStyle(.roundedBorder).frame(width: 52); Text("%")
                if isAutomatic, let effectivePercentage { Text(L10n.Create.autoLld(effectivePercentage)).font(.caption2).foregroundStyle(AppTheme.gold) }
            }
        }.padding(12).frame(width: 150).frame(minHeight: 180).appCard(cornerRadius:20)
        .contextMenu {
            Button(L10n.Create.moveLeft, systemImage: "arrow.left", action: onMoveLeft).disabled(!canMoveLeft)
            Button(L10n.Create.moveRight, systemImage: "arrow.right", action: onMoveRight).disabled(!canMoveRight)
            Button(L10n.Common.delete, systemImage: "trash", role: .destructive, action: onDelete)
        }
    }
}

private struct ComponentPicker: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: ComponentPickerViewModel
    let select: (ComponentOption) -> Void
    init(model: @autoclosure @escaping () -> ComponentPickerViewModel, select: @escaping (ComponentOption) -> Void) {
        _model = StateObject(wrappedValue: model()); self.select = select
    }
    var body: some View {
        NavigationStack {
            List(model.filtered) { option in Button { select(option); dismiss() } label: {
                VStack(alignment: .leading, spacing: 3) { Text(option.flavor).foregroundStyle(.primary); Text(option.brandAndLine).font(.caption).foregroundStyle(.secondary) }
            } }
            .searchable(text: $model.search, prompt: L10n.Create.search).appScreenBackground()
            .safeAreaInset(edge: .top) { Picker(L10n.Create.source, selection: $model.source) {
                ForEach(ComponentSource.allCases, id: \.self) { Text($0.title).tag($0) }
            }.pickerStyle(.segmented).padding(.horizontal).background(.bar) }
            .navigationTitle(L10n.Create.choose).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L10n.Common.close) { dismiss() } } }
        }
    }
}
