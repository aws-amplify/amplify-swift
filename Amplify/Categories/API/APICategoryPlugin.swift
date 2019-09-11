//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol APICategoryPlugin: Plugin, APICategoryPluginBehavior, APICategoryClientBehavior { }

public extension APICategoryPlugin {
    var categoryType: CategoryType {
        return .api
    }
}

public protocol APICategoryPluginBehavior {
    func prepareRequestBody(_ request: APIRequest) throws -> APIRequest
    func authorizeRequest(_ request: APIRequest) throws -> APIRequest
    func invoke(_ request: APIRequest)
    func validateResponse(_ response: APIResponse)
    func serializeResponse(_ response: APIResponse)
}

public protocol APIPluginSelector: PluginSelector, APICategoryClientBehavior { }

public enum HTTPMethod: String {
    case delete = "DELETE"
    case get = "GET"
    case head = "HEAD"
    case options = "OPTIONS"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
}
