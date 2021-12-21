//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

extension AuthEvent {

    static let allEvents: [AuthEvent] = [
        configureAuth,
        configureAuthentication,
        configureAuthorization,
        authenticationConfigured,
        authorizationConfigured
    ]

    static let configureAuth = AuthEvent(id: "configureAuth",
                                         eventType: .configureAuth(.testData))

    static let configureAuthentication = AuthEvent(id: "configureAuthentication",
                                                   eventType: .configureAuthentication(.testData))

    static let configureAuthorization = AuthEvent(id: "configureAuthentication",
                                                  eventType: .configureAuthorization(.testData))

    static let authenticationConfigured = AuthEvent(id: "configureAuthentication",
                                                    eventType: .authenticationConfigured(.testData))

    static let authorizationConfigured = AuthEvent(id: "configureAuthentication",
                                                   eventType: .authorizationConfigured(.testData))
}

