//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStoreCategoryPlugin

class MockRequestRetryablePolicy: RequestRetryablePolicy {

    var responseStack: [RequestRetryAdvice] = []

    func pushOnRetryRequestAdvice(response: RequestRetryAdvice) {
        responseStack.append(response)
    }

    override func retryRequestAdvice(urlError: URLError?, httpURLResponse: HTTPURLResponse?, attemptNumber: Int) -> RequestRetryAdvice {
        //If this breaks, you didn't push anything onto the stack
        let result = responseStack.first!
        responseStack.remove(at: 0)
        return result

    }
}
