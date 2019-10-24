//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPICategoryPlugin {

    func get(apiName: String,
             path: String,
             listener: APIOperation.EventListener?) -> APIOperation {
        let options = APIGetRequest.Options()
        let request = APIGetRequest(apiName: apiName,
                                    path: path,
                                    options: options)

        var task = httpTransport.task(for: request)
        task.delegate = self

        let operation = AWSAPIOperation(request: request,
                                        eventName: HubPayload.EventName.API.get,
                                        listener: listener)

        mapper.addPair(operation: operation, task: task)

        task.resume()

        return operation
    }

}

extension AWSAPICategoryPlugin: HTTPTransportTaskDelegate {
    func task(_ httpTransportTask: HTTPTransportTask, didReceiveData data: Data) {
        let operation = mapper.operation(for: httpTransportTask)
        operation?.dispatch(event: .completed(data))
    }
}
