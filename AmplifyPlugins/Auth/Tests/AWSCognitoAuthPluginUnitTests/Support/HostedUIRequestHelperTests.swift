//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@testable import AWSCognitoAuthPlugin
import Amplify
import XCTest

class HostedUIRequestHelperTests: XCTestCase {
    private var configuration: HostedUIConfigurationData!
    private let result = HostedUIResult(
        code: "code",
        state: "state",
        codeVerifier: "codeVerifier",
        options: .init(
            scopes: [],
            providerInfo: .init(
                authProvider: nil,
                idpIdentifier: nil
            ),
            presentationAnchor: nil,
            preferPrivateSession: false)
    )

    override func setUp() {
        createConfiguration()
    }

    override func tearDown() {
        configuration = nil
    }

    private var encodedSecret: String? {
        guard let clientSecret = configuration.clientSecret,
              let value = "\(configuration.clientId):\(clientSecret)".data(using: .utf8) else {
            return nil
        }

        return value.base64EncodedString()
    }

    private func createConfiguration(clientSecret: String? = nil) {
        configuration = .init(
            clientId: "clientId",
            oauth: .init(
                domain: "domain",
                scopes: [],
                signInRedirectURI: "app://",
                signOutRedirectURI: "app://"
            ),
            clientSecret: clientSecret
        )
    }

    /// Given: A HostedUI configuration without a client secret
    /// When: HostedUIRequestHelper.createTokenRequest is invoked with said configuration
    /// Then: A request is generated that does not include an Authorization header
    func testCreateTokenRequest_withoutClientSecret_shouldNotAddAuthorizationHeader() throws {
        let request = try HostedUIRequestHelper.createTokenRequest(
            configuration: configuration,
            result: result
        )

        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    /// Given: A HostedUI configuration that defines a client secret
    /// When: HostedUIRequestHelper.createTokenRequest is invoked with said configuration
    /// Then: A request is generated that includes an Authorization header and its value has an encoded version of the secret
    func testCreateTokenRequest_withClientSecret_shouldEncodeSecretAndAddAuthorizationHeader() throws {
        createConfiguration(clientSecret: "clientSecret")
        let request = try HostedUIRequestHelper.createTokenRequest(
            configuration: configuration,
            result: result
        )

        let header = try XCTUnwrap(request.value(forHTTPHeaderField: "Authorization"))
        let encodedSecret = try XCTUnwrap(encodedSecret)
        XCTAssertEqual("Basic \(encodedSecret)", header)
    }

    /// Given: A HostedUI configuration without a client secret
    /// When: HostedUIRequestHelper.createRefreshTokenRequest is invoked with said configuration
    /// Then: A request is generated that does not include an Authorization header
    func testCreateRefreshTokenRequest_withoutClientSecret_shouldNotAddAuthorizationHeader() throws {
        let request = try HostedUIRequestHelper.createRefreshTokenRequest(
            refreshToken: "refreshToken",
            configuration: configuration
        )

        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    /// Given: A HostedUI configuration that defines a client secret
    /// When: HostedUIRequestHelper.createRefreshTokenRequest is invoked with said configuration
    /// Then: A request is generated that includes an Authorization header and its value has an encoded version of the secret
    func testCreateRefreshTokenRequest_withClientSecret_shouldEncodeSecretAndAddAuthorizationHeader() throws {
        createConfiguration(clientSecret: "clientSecret")
        let request = try HostedUIRequestHelper.createRefreshTokenRequest(
            refreshToken: "refreshToken",
            configuration: configuration
        )

        let header = try XCTUnwrap(request.value(forHTTPHeaderField: "Authorization"))
        let encodedSecret = try XCTUnwrap(encodedSecret)
        XCTAssertEqual("Basic \(encodedSecret)", header)
    }
}
