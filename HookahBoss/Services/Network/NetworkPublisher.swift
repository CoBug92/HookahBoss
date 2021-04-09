//
//  NetworkPublisher.swift
//  HookahBoss
//
//  Created by Богдан Костюченко on 09.04.2021.
//

import Combine
import Foundation

struct NetworkPublisher {

    // MARK: - Typealias
    typealias Output = Data
    typealias Failure = NetworkError

    // MARK: - Properties
    private let dataPublisher: AnyPublisher<Output, Failure>

    // MARK: - Init/Deinit
    init(request: URLRequest, jsonDecoder: JSONDecoder = JSONDecoder(), shouldPrintResponse: Bool = false) {
        dataPublisher = URLSession.shared.dataTaskPublisher(for: request)
            .mapError { Failure.urlError($0) }
            .flatMap { data, response -> AnyPublisher<Output, Failure> in
                guard let response = response as? HTTPURLResponse else {
                    return Fail(error: Failure.httpResponseError("Not a http response."))
                        .eraseToAnyPublisher()
                }
                if 200..<299 ~= response.statusCode {
                    #if DEBUG
                    if shouldPrintResponse {
                        debugPrint(data.prettyPrintedJSONString ?? "Unable to form a string from a response json.")
                    }
                    #endif
                    return Just(data)
                        .setFailureType(to: Failure.self)
                        .eraseToAnyPublisher()
                } else if let error = try? jsonDecoder.decode(EndpointError.self, from: data) {
                    return Fail(error: .error(error))
                        .eraseToAnyPublisher()
                } else {
                    return Fail(error: NetworkError.decodingError("Unknown decoding error"))
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Data {
        dataPublisher.receive(subscriber: subscriber)
    }

}

#if DEBUG
private extension Data {

    var prettyPrintedJSONString: NSString? {
        guard
            let object = try? JSONSerialization.jsonObject(with: self, options: []),
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
            let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        else { return nil }
        return prettyPrintedString
    }

}
#endif
