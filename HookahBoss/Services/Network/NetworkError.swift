//
//  NetworkError.swift
//  HookahBoss
//
//  Created by Богдан Костюченко on 09.04.2021.
//

import Foundation

enum NetworkError: Error {
    case invalidUrl
    case decodingError(String)
    case urlError(URLError)
    case httpResponseError(String)
    case error(EndpointError)
}
