//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class StorageTransferResponse {
    let task: URLSessionTask
    let httpResponse: HTTPURLResponse?
    let error: Error?
    let transferTask: StorageTransferTask

    var userInfo: [AnyHashable: Any]? {
        guard let httpResponse = httpResponse else {
            return nil
        }
        return httpResponse.allHeaderFields
    }

    var responseError: StorageError? {
        let error: StorageError?
        if let httpResponse = httpResponse {
            let statusCode = httpResponse.statusCode
            if statusCode / 100 == 3, statusCode != 304 {
                // 300 range: Redirection
                error = .httpStatusError(statusCode, "Redirection error", self.error)
            } else if statusCode / 100 == 4 {
                // 400 range: Client Error
                let description = errorDescription(forStatusCode: statusCode)
                if [401, 403].contains(statusCode) {
                    error = .accessDenied(description,
                                          "Make sure the user has access to the key before trying to download it.",
                                          self.error)
                } else if 404 == statusCode {
                    error = .keyNotFound(transferTask.key,
                                         description,
                                         "Make sure the key exists before trying to download it.",
                                         self.error)
                } else {
                    error = .httpStatusError(statusCode, "Client error", self.error)
                }
            } else if statusCode / 100 == 5 {
                // 500 range: Server Error
                error = .httpStatusError(statusCode, "Server error", self.error)
            } else {
                error = nil
            }
        } else {
            error = .unknown("Response is not an HTTP response", self.error)
        }
        return error
    }

    var isErrorRetriable: Bool {
        // See https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html for S3 error responses

        guard let httpResponse = httpResponse,
            transferTask.retryCount < transferTask.retryLimit else {
            return false
        }

        let result: Bool
        let statusCode = httpResponse.statusCode

        if [500, 503].contains(statusCode) {
            // 500 and 503 are retriable.
            result = true
        } else if 400 == statusCode {
            // 400 is a bad request
            result = false
        } else if (transferTask.responseText ?? "").isEmpty {
            // If we didn't get any more info from the server, error is retriable
            result = true
        } else if let responseText = transferTask.responseText,
            ["RequestTimeout", "ExpiredToken", "TokenRefreshRequired"].contains(responseText) {
            result = true
        } else {
            result = false
        }

        return result
    }

    init(task: URLSessionTask, error: Error?, transferTask: StorageTransferTask) {
        self.httpResponse = task.response as? HTTPURLResponse
        self.task = task
        self.error = error
        self.transferTask = transferTask
    }

    private func errorDescription(forStatusCode statusCode: Int) -> ErrorDescription {
        let description: String
        switch statusCode {
        case 401:
            description = "Unauthorized"
        case 403:
            description = "Forbidden"
        case 404:
            description = "NotFound"
        default:
            description = ""
        }

        return "Received HTTP Response status code \(statusCode) \(description)"
    }
}
