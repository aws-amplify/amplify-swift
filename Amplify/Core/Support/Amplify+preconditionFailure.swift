//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Amplify {

    @discardableResult
    public static func preconditionFailure<T>(_ message: @autoclosure () -> String = String(),
                                              file: StaticString = #file,
                                              line: UInt = #line) -> T {
        guard let instanceFactory = AmplifyTesting.getInstanceFactory() else {
            Swift.preconditionFailure(message(), file: file, line: line)
        }
        do {
            return try instanceFactory.get(type: T.self, message: message())
        } catch {
            fatalError("Error: \(error)", file: file, line: line)
        }
    }

}
