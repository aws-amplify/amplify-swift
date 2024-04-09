//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

@_spi(AmplifyAPI)
extension Array where Element == Error {
    func cast<T>(to type: T.Type) -> [T]? {
        self.reduce([]) { partialResult, ele in
            if let partialResult, let ele = ele as? T {
                return partialResult + [ele]
            }
            return nil
        }
    }
}
