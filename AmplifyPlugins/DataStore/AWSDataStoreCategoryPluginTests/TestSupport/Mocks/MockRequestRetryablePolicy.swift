//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin

class MockRequestRetryablePolicy: RequestRetryablePolicy {

    var responseQueue: [RequestRetryAdvice] = []
    var onRetryRequestAdvice: ((URLError?, HTTPURLResponse?, Int) -> Void)?

    func pushOnRetryRequestAdvice(response: RequestRetryAdvice) {
        responseQueue.append(response)
    }

    func setOnRetryRequestAdvice(onRetryRequestAdvice: @escaping (URLError?, HTTPURLResponse?, Int) -> Void) {
        self.onRetryRequestAdvice = onRetryRequestAdvice
    }

    override func retryRequestAdvice(urlError: URLError?,
                                     httpURLResponse: HTTPURLResponse?,
                                     attemptNumber: Int) -> RequestRetryAdvice {
        onRetryRequestAdvice?(urlError, httpURLResponse, attemptNumber)
        // If this breaks, you didn't push anything onto the queue
        return responseQueue.removeFirst()
    }
}
