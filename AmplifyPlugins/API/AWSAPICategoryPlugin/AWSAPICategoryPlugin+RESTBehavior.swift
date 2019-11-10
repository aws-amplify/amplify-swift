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
             listener: RESTOperation.EventListener?) -> RESTOperation {

        let request = RESTRequest(apiName: apiName,
                                       operationType: .get,
                                       path: path,
                                       options: RESTRequest.Options())

        let operation = AWSRESTOperation(request: request,
                                        eventName: HubPayload.EventName.API.get,
                                        session: session,
                                        mapper: mapper,
                                        pluginConfig: pluginConfig,
                                        listener: listener)
        queue.addOperation(operation)

        return operation
    }

    func post(apiName: String,
              path: String,
              body: Data?,
              listener: ((AsyncEvent<Void, Data, APIError>) -> Void)?) -> RESTOperation {
        let request = RESTRequest(apiName: apiName,
                                        operationType: .post,
                                        path: path,
                                        body: body,
                                        options: RESTRequest.Options())

        let operation = AWSRESTOperation(request: request,
                                        eventName: HubPayload.EventName.API.post,
                                        session: session,
                                        mapper: mapper,
                                        pluginConfig: pluginConfig,
                                        listener: listener)

        queue.addOperation(operation)

        return operation
    }
}
