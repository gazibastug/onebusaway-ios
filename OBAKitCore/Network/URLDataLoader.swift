//
//  URLDataLoader.swift
//  OBAKitCore
//
//  Copyright © Open Transit Software Foundation
//  This source code is licensed under the Apache 2.0 license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public protocol URLDataLoader: NSObjectProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLDataLoader { }
