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
        validateCredentialAndConfiguration,
        configureAuthentication,
        configureAuthorization,
        authenticationConfigured,
        authorizationConfigured
    ]

    static let configureAuth = AuthEvent(
        id: "configureAuth",
        eventType: .configureAuth(.testData))

    static let configureAuthentication = AuthEvent(
        id: "configureAuthentication",
        eventType: .configureAuthentication(.testData, .testData))

    static let configureAuthorization = AuthEvent(
        id: "configureAuthorization",
        eventType: .configureAuthorization(.testData, .testData))

    static let authenticationConfigured = AuthEvent(
        id: "authenticationConfigured",
        eventType: .authenticationConfigured(.testData, .testData))

    static let authorizationConfigured = AuthEvent(
        id: "authorizationConfigured",
        eventType: .authorizationConfigured)

    static let validateCredentialAndConfiguration = AuthEvent(
        id: "validateCredentialAndConfiguration",
        eventType: .validateCredentialAndConfiguration(.testData, .testData))

}
