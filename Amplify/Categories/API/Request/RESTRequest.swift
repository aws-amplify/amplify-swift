//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class RESTRequest {

    /// The name of REST API being invoked, as specified in `amplifyconfiguration.json`.
    /// Specify this parameter when more than one REST API is configured.
    public let apiName: String?

    /// Path of the resource
    public let path: String?

    /// Headers
    public let headers: [String: String]?

    /// Query parameters
    public let queryParameters: [String: String]?

    /// Body content
    public let body: Data?

    public init(apiName: String? = nil,
                path: String? = nil,
                headers: [String: String]? = nil,
                queryParameters: [String: String]? = nil,
                body: Data? = nil) {
        self.apiName = apiName
        self.path = path
        self.headers = headers
        self.queryParameters = queryParameters
        self.body = body
    }
}
