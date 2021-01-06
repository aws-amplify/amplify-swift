//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Behavior of the API category related to REST operations
public protocol APICategoryRESTBehavior {

    /// Perform an HTTP GET operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body.
    /// - Returns: An operation that can be observed for its value
    @discardableResult
    func get(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation

    /// Perform an HTTP PUT operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body.
    /// - Returns: An operation that can be observed for its value
    @discardableResult
    func put(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation

    /// Perform an HTTP POST operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body.
    /// - Returns: An operation that can be observed for its value
    @discardableResult
    func post(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation

    /// Perform an HTTP DELETE operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body.
    /// - Returns: An operation that can be observed for its value
    @discardableResult
    func delete(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation

    /// Perform an HTTP HEAD operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body.
    /// - Returns: An operation that can be observed for its value
    @discardableResult
    func head(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation

    /// Perform an HTTP PATCH operation
    ///
    /// - Parameter request: Contains information such as path, query parameters, body.
    /// - Returns: An operation that can be observed for its value
    @discardableResult
    func patch(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation
}
