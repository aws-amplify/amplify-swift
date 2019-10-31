//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSAPIOperation: TaskOperationBehavior {
    func getOperationId() -> UUID {
        return id
    }

    func cancelOperation() {
        cancel()
    }

    func complete(with error: Error?) {
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

    func updateProgress(_ data: Data) {
        self.data.append(data)
    }
}
