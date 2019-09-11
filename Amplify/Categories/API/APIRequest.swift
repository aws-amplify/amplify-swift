//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol APIRequest {
    var apiName: String { get }
    var resourcePath: String { get }
    var options: [String: Any] { get }
    var method: HTTPMethod { get }
    var rawRequest: HTTPURLResponse? { get }
}

public struct BasicAPIRequest: APIRequest {
    public let apiName: String
    public let resourcePath: String
    public let options: [String: Any]
    public let method: HTTPMethod
    public var rawRequest: HTTPURLResponse?
}
