//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// No-listener versions of the public APIs, to clean call sites that use Combine
// publishers to get results

extension APICategoryRESTBehavior {
    /// Perform an HTTP GET operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body.
    /// - Returns: An operation that can be observed for its value
    public func get(request: RESTRequest) -> RESTOperation {
        get(request: request, listener: nil)
    }

    /// Perform an HTTP PUT operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body.
    /// - Returns: An operation that can be observed for its value
    public func put(request: RESTRequest) -> RESTOperation {
        put(request: request, listener: nil)
    }

    /// Perform an HTTP POST operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body.
    /// - Returns: An operation that can be observed for its value
    public func post(request: RESTRequest) -> RESTOperation {
        post(request: request, listener: nil)
    }

    /// Perform an HTTP DELETE operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body.
    /// - Returns: An operation that can be observed for its value
    public func delete(request: RESTRequest) -> RESTOperation {
        delete(request: request, listener: nil)
    }

    /// Perform an HTTP HEAD operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body.
    /// - Returns: An operation that can be observed for its value
    public func head(request: RESTRequest) -> RESTOperation {
        head(request: request, listener: nil)
    }

    /// Perform an HTTP PATCH operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body.
    /// - Returns: An operation that can be observed for its value
    public func patch(request: RESTRequest) -> RESTOperation {
        patch(request: request, listener: nil)
    }
}
