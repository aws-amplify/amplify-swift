//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct APIOperationResponse {
    let urlError: URLError?
    let httpURLResponse: HTTPURLResponse?

    public init(error: Error?, response: URLResponse?) {
        self.urlError = error as? URLError
        self.httpURLResponse = response as? HTTPURLResponse
    }
}

extension APIOperationResponse {

    /// Validate the response from the service and throws APIError if invalid.
    func validate() throws {
        switch (urlError, httpURLResponse) {
        case (nil, nil):
            break
        case (.some(let error), .none):
            throw APIError(urlError: error)
        case (.none, .some(let response)):
            let statusCode = response.statusCode
            if statusCode < 200 || statusCode >= 300 {
                throw APIError.httpStatusError("", "", response)
            }
        case (.some(let error), .some(let response)):
            throw APIError(urlError: error, httpURLResponse: response)
        }
    }
}
