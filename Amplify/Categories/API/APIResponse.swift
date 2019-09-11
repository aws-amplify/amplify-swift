//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol APIResponse {
    var statusCode: Int { get }
    var rawResponse: HTTPURLResponse { get }
}

public struct BasicAPIResponse: APIResponse {
    public let statusCode: Int
    public let rawResponse: HTTPURLResponse
}
