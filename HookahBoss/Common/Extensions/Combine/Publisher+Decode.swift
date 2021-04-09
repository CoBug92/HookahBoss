//
//  Publisher+Decode.swift
//  HookahBoss
//
//  Created by Богдан Костюченко on 09.04.2021.
//

import Combine
import Foundation

extension Publisher {

    func decode<Output: Decodable>(
        type: Output.Type,
        with jsonDecoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<Output, Failure> where Self.Output == Data, Failure == NetworkError {
        flatMap { data -> AnyPublisher<Output, Failure> in
            do {
                return Just(try jsonDecoder.decode(Output.self, from: data))
                    .setFailureType(to: Failure.self)
                    .eraseToAnyPublisher()
            } catch let error as DecodingError {
                return Fail(error: .decodingError("\(error)"))
                    .eraseToAnyPublisher()
            } catch {
                return Fail(error: .decodingError("Unknown decoding error"))
                    .eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }

}
