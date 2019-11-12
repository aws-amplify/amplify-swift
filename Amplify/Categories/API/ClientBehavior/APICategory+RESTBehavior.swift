//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension APICategory: APICategoryRESTBehavior {

    public func get(apiName: String,
                    path: String,
                    listener: RESTOperation.EventListener?) -> RESTOperation {
        return plugin.get(apiName: apiName,
                          path: path,
                          listener: listener)
    }

    public func post(apiName: String,
                     path: String,
                     body: Data?,
                     listener: RESTOperation.EventListener?) -> RESTOperation {
        return plugin.post(apiName: apiName, path: path, body: body, listener: listener)
    }
}
