//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension JSONValue {
    func value(at keyPath: String) -> JSONValue? {
        value(at: keyPath, separatedBy: ".")
    }

    func value<T: StringProtocol>(at keyPath: String,
                                  separatedBy separator: T) -> JSONValue? {
        let pathComponents = keyPath.components(separatedBy: separator)
        let value = pathComponents.reduce(self) { currVal, nextVal in currVal?[nextVal] }
        return value
    }
}
