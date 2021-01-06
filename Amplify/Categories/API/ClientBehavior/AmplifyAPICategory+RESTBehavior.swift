//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AmplifyAPICategory: APICategoryRESTBehavior {
    @discardableResult
    public func get(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.get(request: request, listener: listener)
    }

    @discardableResult
    public func put(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.put(request: request, listener: listener)
    }

    @discardableResult
    public func post(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.post(request: request, listener: listener)
    }

    @discardableResult
    public func delete(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.delete(request: request, listener: listener)
    }

    @discardableResult
    public func head(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.head(request: request, listener: listener)
    }

    @discardableResult
    public func patch(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.patch(request: request, listener: listener)
    }
}
