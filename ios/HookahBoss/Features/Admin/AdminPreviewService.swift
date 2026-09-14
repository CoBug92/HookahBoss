@MainActor
final class AdminPreviewService: AdminServing {
    func adminList(_ resource: AdminResource) async throws -> [AdminRecordDTO] {
        []
    }

    func adminCreate(_ resource: AdminResource, body: [String: JSONValue]) async throws -> AdminRecordDTO {
        throw PreviewError.unsupportedOperation
    }

    func adminUpdate(
        _ resource: AdminResource,
        id: String,
        body: [String: JSONValue]
    ) async throws -> AdminRecordDTO {
        throw PreviewError.unsupportedOperation
    }

    func adminDelete(_ resource: AdminResource, id: String, body: [String: JSONValue]?) async throws {
        throw PreviewError.unsupportedOperation
    }

    private enum PreviewError: Error {
        case unsupportedOperation
    }
}
