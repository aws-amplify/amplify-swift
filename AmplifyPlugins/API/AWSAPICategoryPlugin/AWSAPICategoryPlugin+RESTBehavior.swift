//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension AWSAPICategoryPlugin {

    func get(apiName: String,
             path: String,
             listener: APIOperation.EventListener?) -> APIOperation {

        let apiGetRequest = APIRequest(apiName: apiName,
                                       operationType: .get,
                                       path: path,
                                       options: APIRequest.Options())

        let operation = AWSAPIOperation(request: apiGetRequest,
                                        eventName: HubPayload.EventName.API.get,
                                        listener: listener,
                                        session: session,
                                        mapper: mapper,
                                        pluginConfig: pluginConfig)
        queue.addOperation(operation)

        return operation
    }

    func post(apiName: String,
              path: String,
              body: String?,
              listener: ((AsyncEvent<Void, Data, APIError>) -> Void)?) -> APIOperation {
        let apiPostRequest = APIRequest(apiName: apiName,
                                        operationType: .post,
                                        path: path,
                                        body: body,
                                        options: APIRequest.Options())

        let operation = AWSAPIOperation(request: apiPostRequest,
                                        eventName: HubPayload.EventName.API.post,
                                        listener: listener,
                                        session: session,
                                        mapper: mapper,
                                        pluginConfig: pluginConfig)

        queue.addOperation(operation)

        return operation
    }
}
