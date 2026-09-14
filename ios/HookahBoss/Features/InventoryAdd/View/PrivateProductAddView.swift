import SwiftUI

struct PrivateProductAddView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var brand = TechnicalString.empty
    @State private var line = TechnicalString.empty
    @State private var flavor = TechnicalString.empty
    @State private var profiles: Set<FlavorProfile> = []
    @State private var error = false
    let onCreate: (String, String?, String, [String], @escaping (Bool) -> Void) -> Void

    // MARK: - Computed properties

    private var isSaveDisabled: Bool {
        brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || flavor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Layout

    var body: some View {
        NavigationStack {
            Form {
                TextField(L10n.Inventory.Private.brand, text: $brand)
                TextField(L10n.Inventory.Private.line, text: $line)
                TextField(L10n.Inventory.Private.flavor, text: $flavor)
                Section(L10n.Filters.profiles) {
                    ForEach(FlavorProfile.allCases) { profile in
                        Toggle(profile.title, isOn: profileBinding(profile))
                    }
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle(L10n.Inventory.addPrivate)
            .appScreenBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save, action: save)
                        .disabled(isSaveDisabled)
                }
            }
            .alert(L10n.Content.Error.title, isPresented: $error) {
                Button(L10n.Common.close) {}
            }
        }
    }

    // MARK: - Private methods

    private func profileBinding(_ profile: FlavorProfile) -> Binding<Bool> {
        Binding(
            get: { profiles.contains(profile) },
            set: { selected in
                if selected {
                    profiles.insert(profile)
                } else {
                    profiles.remove(profile)
                }
            }
        )
    }

    private func save() {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        onCreate(
            brand,
            trimmed.isEmpty ? nil : trimmed,
            flavor,
            profiles.map(\.rawValue)
        ) { succeeded in
            if succeeded {
                dismiss()
            } else {
                error = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PrivateProductAddView { _, _, _, _, completion in
        completion(true)
    }
}
