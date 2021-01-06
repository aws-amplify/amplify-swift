//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct URLSessionFactory: URLSessionBehaviorFactory {
    let configuration: URLSessionConfiguration
    let delegateQueue: OperationQueue?

    func makeSession(withDelegate delegate: URLSessionBehaviorDelegate?) -> URLSessionBehavior {
        let urlSessionDelegate = delegate?.asURLSessionDelegate
        let session = URLSession(configuration: configuration,
                                 delegate: urlSessionDelegate,
                                 delegateQueue: delegateQueue)
        return session
    }

}
