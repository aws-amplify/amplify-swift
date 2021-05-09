//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct RESTOperationRequest: AmplifyOperationRequest {

    /// The name of the API to perform the request against
    public let apiName: String?

    /// The type of HTTP operation
    public let operationType: RESTOperationType

    /// path of the resource
    public let path: String?

    /// Request headers
    public let headers: [String: String]?

    /// Query parameters
    public let queryParameters: [String: String]?

    /// Content body
    public let body: Data?

    /// Options to adjust the behavior of this request, including plugin-options
    public let options: Options

    /// <#Description#>
    /// - Parameters:
    ///   - apiName: <#apiName description#>
    ///   - operationType: <#operationType description#>
    ///   - path: <#path description#>
    ///   - headers: <#headers description#>
    ///   - queryParameters: <#queryParameters description#>
    ///   - body: <#body description#>
    ///   - options: <#options description#>
    public init(apiName: String?,
                operationType: RESTOperationType,
                path: String? = nil,
                headers: [String: String]? = nil,
                queryParameters: [String: String]? = nil,
                body: Data? = nil,
                options: Options) {
        self.apiName = apiName
        self.operationType = operationType
        self.path = path
        self.headers = headers
        self.queryParameters = queryParameters
        self.body = body
        self.options = options
    }
}

public extension RESTOperationRequest {

    /// <#Description#>
    struct Options {

        /// <#Description#>
        public init() { }
    }
}
