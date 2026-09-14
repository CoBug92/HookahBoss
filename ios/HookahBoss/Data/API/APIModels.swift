struct APIEnvelope<Value: Decodable>: Decodable {
    let data: Value
}

struct CursorPaginationDTO: Decodable, Equatable {
    let nextCursor: String?
    let hasMore: Bool
}

struct CursorPageEnvelope<Value: Decodable>: Decodable {
    let data: Value
    let pagination: CursorPaginationDTO
}
