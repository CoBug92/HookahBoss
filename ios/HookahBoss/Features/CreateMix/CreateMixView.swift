import SwiftUI

struct CreateMixView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: CreateMixViewModel
    @State private var isPickerPresented = false

    // MARK: - Init

    init(model: @autoclosure @escaping () -> CreateMixViewModel) {
        _model = StateObject(wrappedValue: model())
    }

    // MARK: - Layout

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Margin.x(13)) {
                    Text(L10n.Create.title)
                        .font(.system(size: .titleFontSize, weight: .bold, design: .serif))
                        .tracking(.titleTracking)
                    TextField(L10n.Create.Title.placeholder, text: $model.title)
                        .font(.title2.weight(.semibold))
                        .padding(Margin.x9)
                        .appCard(cornerRadius: .titleFieldCornerRadius)
                    VStack(alignment: .leading, spacing: Margin.x6) {
                        Text(L10n.Create.composition)
                            .font(.title2.weight(.semibold))
                        if model.components.isEmpty {
                            firstComponent
                        } else {
                            componentStrip
                        }
                    }
                    if model.showValidation, let message = model.validationMessage {
                        Label(message, systemImage: AppSymbol.error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
                .padding(Margin.x10)
            }
            .overlay {
                if model.isLoading {
                    ProgressView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if model.isSaving {
                        ProgressView()
                    } else {
                        Button(L10n.Common.save) {
                            model.save()
                        }
                        .fontWeight(.semibold)
                        .disabled(model.isLoading)
                    }
                }
            }
            .sheet(isPresented: $isPickerPresented) {
                ComponentPicker(
                    model: ComponentPickerViewModel(
                        snapshot: model.options,
                        excluding: Set(model.components.map(\.optionKey))
                    ),
                    select: model.add
                )
            }
            .onAppear {
                model.appear()
            }
            .onChange(of: model.didSave) { _, saved in
                if saved {
                    dismiss()
                }
            }
            .alert(
                L10n.Content.Error.title,
                isPresented: Binding(
                    get: { model.errorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            model.clearError()
                        }
                    }
                )
            ) {
                Button(L10n.Common.close) {
                    model.clearError()
                }
                Button(L10n.Common.retry) {
                    model.retry()
                }
            } message: {
                Text(model.errorMessage ?? "")
            }
            .background(AppTheme.background)
        }
    }

    private var componentStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: Margin.x6) {
                ForEach(Array(model.components.enumerated()), id: \.element.id) { index, component in
                    DraftComponentCard(
                        component: component,
                        percentageText: Binding(
                            get: { model.percentageBinding(at: index) },
                            set: { model.setPercentage($0, at: index) }
                        ),
                        effectivePercentage: model.effectivePercentage(at: index),
                        isAutomatic: model.automaticIndices.contains(index),
                        canMoveLeft: index > 0,
                        canMoveRight: index < model.components.count - 1,
                        onDelete: { model.delete(at: index) },
                        onMoveLeft: { model.moveLeft(from: index) },
                        onMoveRight: { model.moveRight(from: index) }
                    )
                }
                addCard
            }
            .padding(.vertical, Margin.x1)
        }
    }

    private var firstComponent: some View {
        Button {
            isPickerPresented = true
        } label: {
            VStack(spacing: Margin.x6) {
                Image(systemName: AppSymbol.createFilled)
                    .font(.system(size: .titleFontSize))
                    .foregroundStyle(AppTheme.gold)
                Text(L10n.Create.firstComponent)
                    .font(.headline)
                Text(L10n.Create.FirstComponent.hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: .firstComponentHeight)
            .appCard(cornerRadius: .firstComponentCornerRadius)
        }
        .buttonStyle(.plain)
        .disabled(model.isLoading)
    }

    private var addCard: some View {
        Button {
            isPickerPresented = true
        } label: {
            VStack(spacing: Margin.x4) {
                Image(systemName: AppSymbol.create)
                    .font(.title2)
                Text(L10n.Create.add)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(AppTheme.gold)
            .frame(width: .addCardWidth, height: .componentCardHeight)
            .background(
                AppTheme.gold.opacity(.addCardBackgroundOpacity),
                in: RoundedRectangle(cornerRadius: Margin.x10)
            )
        }
        .buttonStyle(.plain)
        .disabled(model.isLoading)
    }
}

private struct DraftComponentCard: View {
    let component: DraftComponent
    @Binding var percentageText: String
    let effectivePercentage: Int?
    let isAutomatic: Bool
    let canMoveLeft: Bool
    let canMoveRight: Bool
    let onDelete: () -> Void
    let onMoveLeft: () -> Void
    let onMoveRight: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x4) {
            HStack(spacing: Margin.x4) {
                Text(component.option.source.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: AppSymbol.clear)
                        .foregroundStyle(.secondary)
                        .frame(width: .deleteButtonSize, height: .deleteButtonSize)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.Common.delete))
            }
            Text(component.option.flavor)
                .font(.headline)
                .lineLimit(2)
            Text(component.option.brandAndLine)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer()
            HStack(spacing: Margin.x3) {
                TextField("—", text: $percentageText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: .percentageFieldWidth)
                Text("%")
                if isAutomatic, let effectivePercentage {
                    Text(L10n.Create.autoLld(effectivePercentage))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .padding(Margin.x6)
        .frame(width: .componentCardWidth)
        .frame(minHeight: .componentCardHeight)
        .appCard(cornerRadius: Margin.x10)
        .contextMenu {
            Button(L10n.Create.moveLeft, systemImage: AppSymbol.back, action: onMoveLeft)
                .disabled(!canMoveLeft)
            Button(L10n.Create.moveRight, systemImage: AppSymbol.forward, action: onMoveRight)
                .disabled(!canMoveRight)
            Button(L10n.Common.delete, systemImage: AppSymbol.trash, role: .destructive, action: onDelete)
        }
    }
}

private struct ComponentPicker: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: ComponentPickerViewModel
    let select: (ComponentOption) -> Void

    init(
        model: @autoclosure @escaping () -> ComponentPickerViewModel,
        select: @escaping (ComponentOption) -> Void
    ) {
        _model = StateObject(wrappedValue: model())
        self.select = select
    }
    var body: some View {
        NavigationStack {
            List(model.filtered) { option in
                Button {
                    select(option)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: Margin.x2) {
                        Text(option.flavor)
                            .foregroundStyle(.primary)
                        Text(option.brandAndLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .searchable(text: $model.search, prompt: L10n.Create.search).appScreenBackground()
            .safeAreaInset(edge: .top) {
                Picker(L10n.Create.source, selection: $model.source) {
                    ForEach(ComponentSource.allCases, id: \.self) {
                        Text($0.title)
                            .tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Margin.x8)
                .background(.bar)
            }
            .navigationTitle(L10n.Create.choose)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.close) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let titleFontSize: CGFloat = 34
    static let titleTracking: CGFloat = -0.7
    static let titleFieldCornerRadius: CGFloat = 18
    static let firstComponentHeight: CGFloat = 170
    static let firstComponentCornerRadius: CGFloat = 22
    static let addCardWidth: CGFloat = 112
    static let componentCardWidth: CGFloat = 150
    static let componentCardHeight: CGFloat = 180
    static let deleteButtonSize: CGFloat = 44
    static let percentageFieldWidth: CGFloat = 52
}

private extension Double {
    static let addCardBackgroundOpacity = 0.1
}

@MainActor
private final class PreviewCreateMixService: CreateMixServing {
    func loadOptions(locale: AppLocale) async throws -> CreateMixOptionSnapshot {
        CreateMixOptionSnapshot(catalog: [], personal: [], inventory: [])
    }

    func save(_ mix: PersonalMixRecord) async throws {}
}

// MARK: - Preview

#Preview {
    CreateMixView(model: CreateMixViewModel(service: PreviewCreateMixService()))
}
