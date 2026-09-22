//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven

// by a single test at a time.

class MockAuthHubEventBehavior: AuthHubEventBehavior, @unchecked Sendable {
    func sendUserSignedInEvent() {
        // Incomplete implementation
    }

    func sendUserSignedOutEvent() {
        // Incomplete implementation
    }

    func sendUserDeletedEvent() {
        // Incomplete implementation
    }

    func sendSessionExpiredEvent() {
        // Incomplete implementation
    }
}
