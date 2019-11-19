//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSRESTOperation: APIOperation {
    func getOperationId() -> UUID {
        return id
    }

    func cancelOperation() {
        cancel()
    }

    func updateProgress(_ data: Data, response: URLResponse?) {
        if isCancelled || isFinished {
            finish()
            return
        }

        guard let response = response as? HTTPURLResponse else {
            let apiError = APIError.unknown("Could not retrieve HTTPURLResponse", "")
            dispatch(event: .failed(apiError))
            finish()
            return
        }

        let statusCode = response.statusCode

        if statusCode < 200 || statusCode >= 300 {
            let headers = response.allHeaderFields
            let apiError = APIError.httpStatusError(statusCode, headers, "")
            dispatch(event: .failed(apiError))
            finish()
            return
        }

        self.data.append(data)
    }

    func complete(with error: Error?, response: URLResponse?) {
        if isCancelled || isFinished {
            finish()
            return
        }

        guard let response = response as? HTTPURLResponse else {
            let apiError = APIError.unknown("Could not retrieve HTTPURLResponse", "", error)
            dispatch(event: .failed(apiError))
            finish()
            return
        }

        let statusCode = response.statusCode

        if statusCode < 200 || statusCode >= 300 {
            let headers = response.allHeaderFields
            let apiError = APIError.httpStatusError(statusCode, headers, "", error)
            dispatch(event: .failed(apiError))
            finish()
            return
        }

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
            finish()
            return
        }

        dispatch(event: .completed(data))
        finish()
    }
}
