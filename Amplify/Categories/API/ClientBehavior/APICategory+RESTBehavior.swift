//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension APICategory: APICategoryRESTBehavior {

    public func get(apiName: String,
                    path: String,
                    listener: APIOperation.EventListener?) -> APIOperation {
        return plugin.get(apiName: apiName,
                          path: path,
                          listener: listener)
    }

    public func post(apiName: String,
                     path: String,
                     body: String?,
                     listener: APIOperation.EventListener?) -> APIOperation {
        return plugin.post(apiName: apiName, path: path, body: body, listener: listener)
    }
}
