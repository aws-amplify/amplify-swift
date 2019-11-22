//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct RequestRetryAdvice {
    let shouldRetry: Bool
    let retryInterval: DispatchTimeInterval?

}

protocol RequestRetryable {
    func retryRequestAdvice(urlError: URLError?,
                            httpURLResponse: HTTPURLResponse?,
                            attemptNumber: Int) -> RequestRetryAdvice
}
