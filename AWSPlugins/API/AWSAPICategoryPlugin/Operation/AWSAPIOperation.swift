//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

final public class AWSAPIOperation: AmplifyOperation<APIGetRequest,
    Void,
    Data,
    APIError
    >,
APIOperation {

    // Data received by the operation
    var data = Data()

    init(request: APIGetRequest,
         eventName: String,
         listener: AWSAPIOperation.EventListener?) {
        super.init(categoryType: .api,
                   eventName: HubPayload.EventName.API.get,
                   request: request,
                   listener: listener)

    }

    func didReceive(_ data: Data) {
        self.data.append(data)
    }

    func didComplete(with error: Error?) {
        if let error = error {
            let apiError = APIError.operationError(
                "The operation for this request failed.",
                """
                The operation for the request shown below failed with the following message: \
                \(error.localizedDescription).

                Inspect this error's `.error` property for more information.

                Request:
                \(request)
                """,
                error)

            dispatch(event: .failed(apiError))
            return
        }

        dispatch(event: .completed(data))
    }
}
