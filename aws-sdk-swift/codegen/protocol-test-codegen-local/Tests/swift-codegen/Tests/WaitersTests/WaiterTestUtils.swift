//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import Waiters
import SmithyWaitersAPI

// Convenience test-helper methods for testing acceptor matches

extension WaiterConfiguration.Acceptor.Match: Equatable where Input: Equatable, Output: Equatable {

    public static func == (
        lhs: WaiterConfiguration<Input, Output>.Acceptor.Match,
        rhs: WaiterConfiguration<Input, Output>.Acceptor.Match
    ) -> Bool {
        switch (lhs, rhs) {
        case (.success(let left), .success(let right)):
            return compare(left, right)
        case (.failure(let left), .failure(let right)):
            return compare(left, right)
        case (.retry, .retry):
            return true
        default:
            return false
        }
    }

    private static func compare(_ lhs: Result<Output, Error>, _ rhs: Result<Output, Error>) -> Bool {
        switch (lhs, rhs) {
        case (.success(let left), .success(let right)):
            return left == right
        case (.failure(let left), .failure(let right)):
            return left.localizedDescription == right.localizedDescription
        default:
            return false
        }
    }
}

// Allows for the use of a string as an Error, for easy test validation & easy-to-read tests.
extension String: Error {
    var localizedString: String? { self }
}

var anInput = GetWidgetInput()
