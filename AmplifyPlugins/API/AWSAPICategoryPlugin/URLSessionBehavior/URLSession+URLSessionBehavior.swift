//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension URLSession: URLSessionBehavior {
    public func reset(onComplete: BasicClosure?) {
        invalidateAndCancel()
        reset {
            onComplete?()
        }
    }

    public func dataTaskBehavior(with request: URLRequest) -> URLSessionDataTaskBehavior {
        return dataTask(with: request) as URLSessionDataTaskBehavior
    }

    public var sessionBehaviorDelegate: URLSessionBehaviorDelegate? {
        return delegate as? URLSessionBehaviorDelegate
    }

}
