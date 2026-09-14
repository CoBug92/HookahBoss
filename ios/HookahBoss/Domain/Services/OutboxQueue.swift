enum OutboxQueue {
    static func upserting<Item>(
        _ item: Item,
        in items: [Item],
        matches: (Item, Item) -> Bool
    ) -> [Item] {
        items.filter { !matches($0, item) } + [item]
    }

    static func removing<Item, ID: Equatable>(
        _ id: ID,
        from items: [Item],
        id keyPath: KeyPath<Item, ID>
    ) -> [Item] {
        items.filter { $0[keyPath: keyPath] != id }
    }
}
