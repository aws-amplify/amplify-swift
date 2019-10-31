//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AWSAPICategoryPlugin: URLSessionBehaviorDelegate {
    public func urlSessionBehavior(_ session: URLSessionBehavior,
                                   dataTaskBehavior: URLSessionDataTaskBehavior,
                                   didCompleteWithError error: Error?) {
        let operation = mapper.operation(for: dataTaskBehavior)
        operation?.didComplete(with: error)
    }

    public func urlSessionBehavior(_ session: URLSessionBehavior,
                                   dataTaskBehavior: URLSessionDataTaskBehavior,
                                   didReceive data: Data) {
        let operation = mapper.operation(for: dataTaskBehavior)
        operation?.didReceive(data)
    }
}
