import Foundation

enum AdminFormValidator {
    enum ValidationError: LocalizedError, Equatable {
        case required(String)
        case invalid(String)
        case provenance
        case percentages

        var errorDescription: String? {
            switch self {
            case .required(let field):
                L10n.Admin.Validation.required(field)
            case .invalid(let field):
                L10n.Admin.Validation.invalid(field)
            case .provenance:
                L10n.Admin.Validation.provenance
            case .percentages:
                L10n.Admin.Validation.percentages
            }
        }
    }

    static func body(
        resource: AdminResource,
        values: [String: String]
    ) throws -> [String: JSONValue] {
        var body: [String: JSONValue] = [:]
        for field in resource.fields {
            let rawValue = (values[field.key] ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if field.required && rawValue.isEmpty {
                throw ValidationError.required(field.title)
            }
            if rawValue.isEmpty {
                continue
            }
            switch field.kind {
            case .number:
                guard let number = Double(rawValue) else {
                    throw ValidationError.invalid(field.title)
                }
                body[field.key] = .number(number)
            case .json:
                guard
                    let data = rawValue.data(using: .utf8),
                    let value = try? JSONDecoder().decode(JSONValue.self, from: data)
                else {
                    throw ValidationError.invalid(field.title)
                }
                body[field.key] = value
            default:
                body[field.key] = .string(rawValue)
            }
        }

        if let status = values["status"],
           status != "draft",
           ["published", "archived"].contains(status),
           (values["sourceId"] ?? "").isEmpty || (values["verifiedAt"] ?? "").isEmpty {
            throw ValidationError.provenance
        }

        if resource.path == "official-mixes", case .array(let components) = body["components"] {
            let total = components.reduce(0) { sum, item in
                guard case .object(let object) = item,
                      case .number(let percentage) = object["percentage"] else {
                    return sum
                }
                return sum + Int(percentage)
            }
            if total != 100 {
                throw ValidationError.percentages
            }
        }
        return body
    }
}
