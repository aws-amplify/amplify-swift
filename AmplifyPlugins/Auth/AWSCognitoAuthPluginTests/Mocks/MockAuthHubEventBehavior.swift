//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin

class MockAuthHubEventBehavior: AuthHubEventBehavior {

    var interactions: [String] = []

    func sendUserSignedInEvent() {
        interactions.append(#function)
    }

    func sendUserSignedOutEvent() {
        interactions.append(#function)
    }

    func sendUserDeletedEvent() {
        interactions.append(#function)
    }

    func sendSessionExpiredEvent() {
        interactions.append(#function)
    }
}
