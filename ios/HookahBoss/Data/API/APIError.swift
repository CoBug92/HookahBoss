import Foundation

enum APIError: Error, Equatable {
    case invalidURL
    case transport(String)
    case nonHTTPResponse
    case http(status: Int, serverCode: String?, body: Data)
    case decoding(String)
}
