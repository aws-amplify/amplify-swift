//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

// MARK: - Test Data

extension SignOutEvent {

    static let allEvents: [SignOutEvent] = [
        signOutGlobally,
        revokeToken,
        signOutLocally,
        signedOutSuccess,
        signedOutFailure
    ]

    static let signOutGlobally = SignOutEvent(
        id: "signOutGlobally",
        eventType: .signOutGlobally(.testData)
    )

    static let revokeToken = SignOutEvent(
        id: "revokeToken",
        eventType: .revokeToken(.testData)
    )

    static let signOutLocally = SignOutEvent(
        id: "signOutLocally",
        eventType: .signOutLocally(.testData)
    )

    static let signedOutSuccess = SignOutEvent(
        id: "signedOutSuccess",
        eventType: .signedOutSuccess()
    )

    static let signedOutFailure = SignOutEvent(
        id: "signedOutFailure",
        eventType: .signedOutFailure(.testData)
    )
}
