struct AdminField: Identifiable {
    let key: String
    let title: String
    let kind: AdminFieldKind
    let required: Bool

    var id: String {
        key
    }
}
