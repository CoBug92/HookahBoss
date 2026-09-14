import Foundation

struct DraftComponent {
    let id = UUID()
    let option: ComponentOption
    var percentageText = ""

    var optionKey: String {
        option.id
    }
}

// MARK: - Identifiable

extension DraftComponent: Identifiable {}
