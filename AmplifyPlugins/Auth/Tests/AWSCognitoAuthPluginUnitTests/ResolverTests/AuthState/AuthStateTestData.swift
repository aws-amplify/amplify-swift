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
        authorizationConfigured,
        fetchCachedCredentials,
        receivedCachedCredentials,
        cachedCredentialsFailed
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

    static let fetchCachedCredentials = AuthEvent(
        id: "fetchCachedCredentials",
        eventType: .fetchCachedCredentials(.testData))

    static let receivedCachedCredentials = AuthEvent(
        id: "receivedCachedCredentials",
        eventType: .receivedCachedCredentials(.testData))

    static let cachedCredentialsFailed = AuthEvent(
        id: "cachedCredentialsFailed",
        eventType: .cachedCredentialsFailed)
}
