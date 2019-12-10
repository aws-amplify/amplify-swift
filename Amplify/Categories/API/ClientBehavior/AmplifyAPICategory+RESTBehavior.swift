//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AmplifyAPICategory: APICategoryRESTBehavior {
    public func get(request: RESTRequest, listener: RESTOperation.EventListener?) -> RESTOperation {
        plugin.get(request: request, listener: listener)
    }

    public func put(request: RESTRequest, listener: RESTOperation.EventListener?) -> RESTOperation {
        plugin.put(request: request, listener: listener)
    }

    public func post(request: RESTRequest, listener: RESTOperation.EventListener?) -> RESTOperation {
        plugin.post(request: request, listener: listener)
    }

    public func delete(request: RESTRequest, listener: RESTOperation.EventListener?) -> RESTOperation {
        plugin.delete(request: request, listener: listener)
    }

    public func head(request: RESTRequest, listener: RESTOperation.EventListener?) -> RESTOperation {
        plugin.head(request: request, listener: listener)
    }

    public func patch(request: RESTRequest, listener: RESTOperation.EventListener?) -> RESTOperation {
        plugin.patch(request: request, listener: listener)
    }
}
