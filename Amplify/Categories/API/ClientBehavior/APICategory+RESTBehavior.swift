//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension APICategory: APICategoryRESTBehavior {
    
    @discardableResult
    public func get(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.get(request: request, listener: listener)
    }
    
    public func get(request: RESTRequest) async throws -> RESTTask.Success {
        try await plugin.get(request: request)
    }

    @discardableResult
    public func put(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.put(request: request, listener: listener)
    }
    
    public func put(request: RESTRequest) async throws -> RESTTask.Success {
        try await plugin.put(request: request)
    }

    @discardableResult
    public func post(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.post(request: request, listener: listener)
    }
    
    public func post(request: RESTRequest) async throws -> RESTTask.Success {
        try await plugin.post(request: request)
    }

    @discardableResult
    public func delete(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.delete(request: request, listener: listener)
    }
    
    public func delete(request: RESTRequest) async throws -> RESTTask.Success {
        try await plugin.delete(request: request)
    }

    @discardableResult
    public func head(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.head(request: request, listener: listener)
    }
    
    public func head(request: RESTRequest) async throws -> RESTTask.Success {
        try await plugin.head(request: request)
    }

    @discardableResult
    public func patch(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.patch(request: request, listener: listener)
    }
    
    public func patch(request: RESTRequest) async throws -> RESTTask.Success {
        try await plugin.patch(request: request)
    }
}
