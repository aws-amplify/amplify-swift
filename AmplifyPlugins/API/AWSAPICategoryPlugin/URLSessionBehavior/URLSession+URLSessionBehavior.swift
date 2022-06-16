//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension URLSession: URLSessionBehavior {
    public func cancelAndReset() async {
        //invalidateAndCancel()
        //await reset()
    }

    public func dataTaskBehavior(with request: URLRequest) -> URLSessionDataTaskBehavior {
        return dataTask(with: request) as URLSessionDataTaskBehavior
    }

    public var sessionBehaviorDelegate: URLSessionBehaviorDelegate? {
        return delegate as? URLSessionBehaviorDelegate
    }
}
