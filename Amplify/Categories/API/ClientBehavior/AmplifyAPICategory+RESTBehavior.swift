//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AmplifyAPICategory: APICategoryRESTBehavior {
    public func get(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.get(request: request, listener: listener)
    }

    public func put(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.put(request: request, listener: listener)
    }

    public func post(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.post(request: request, listener: listener)
    }

    public func delete(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.delete(request: request, listener: listener)
    }

    public func head(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.head(request: request, listener: listener)
    }

    public func patch(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.patch(request: request, listener: listener)
    }
}
