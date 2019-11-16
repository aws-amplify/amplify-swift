//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension AWSAPICategoryPlugin {

    func get(request: RESTRequest, listener: RESTOperation.EventListener?) -> RESTOperation {
        let operationRequest = getOperationRequest(request: request,
                                                   operationType: .get)

        let operation = AWSRESTOperation(request: operationRequest,
                                         session: session,
                                         mapper: mapper,
                                         pluginConfig: pluginConfig,
                                         listener: listener)

        queue.addOperation(operation)
        return operation
    }

    func put(request: RESTRequest, listener: RESTOperation.EventListener?) -> RESTOperation {
        let operationRequest = getOperationRequest(request: request,
                                                   operationType: .put)

        let operation = AWSRESTOperation(request: operationRequest,
                                         session: session,
                                         mapper: mapper,
                                         pluginConfig: pluginConfig,
                                         listener: listener)

        queue.addOperation(operation)
        return operation
    }

    func post(request: RESTRequest, listener: RESTOperation.EventListener?) -> RESTOperation {
        let operationRequest = getOperationRequest(request: request,
                                                   operationType: .post)

        let operation = AWSRESTOperation(request: operationRequest,
                                         session: session,
                                         mapper: mapper,
                                         pluginConfig: pluginConfig,
                                         listener: listener)

        queue.addOperation(operation)
        return operation
    }

    func patch(request: RESTRequest, listener: RESTOperation.EventListener?) -> RESTOperation {
        let operationRequest = getOperationRequest(request: request, operationType: .patch)

        let operation = AWSRESTOperation(request: operationRequest,
                                         session: session,
                                         mapper: mapper,
                                         pluginConfig: pluginConfig,
                                         listener: listener)

        queue.addOperation(operation)
        return operation
    }

    func delete(request: RESTRequest, listener: RESTOperation.EventListener?) -> RESTOperation {
        let operationRequest = getOperationRequest(request: request,
                                                   operationType: .delete)

        let operation = AWSRESTOperation(request: operationRequest,
                                         session: session,
                                         mapper: mapper,
                                         pluginConfig: pluginConfig,
                                         listener: listener)

        queue.addOperation(operation)
        return operation
    }

    func head(request: RESTRequest, listener: RESTOperation.EventListener?) -> RESTOperation {
        let operationRequest = getOperationRequest(request: request,
                                                   operationType: .head)

        let operation = AWSRESTOperation(request: operationRequest,
                                         session: session,
                                         mapper: mapper,
                                         pluginConfig: pluginConfig,
                                         listener: listener)

        queue.addOperation(operation)
        return operation
    }

    private func getOperationRequest(request: RESTRequest, operationType: RESTOperationType) -> RESTOperationRequest {

        return RESTOperationRequest(apiName: request.apiName,
                                    operationType: operationType,
                                    path: request.path,
                                    queryParameters: request.queryParameters,
                                    body: request.body,
                                    options: RESTOperationRequest.Options())
    }
}
