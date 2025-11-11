//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify
import XCTest
@testable import AWSCognitoAuthPlugin

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
            preferPrivateSession: false,
            nonce: nil,
            language: nil,
            loginHint: nil,
            prompt: nil,
            resource: nil
        )
    )

    override func setUp() {
        createConfiguration()
    }

    override func tearDown() {
        configuration = nil
    }

    private var encodedSecret: String? {
        guard let clientSecret = configuration.clientSecret else {
            return nil
        }
        let value = Data("\(configuration.clientId):\(clientSecret)".utf8)
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

    /// Given: A HostedUI configuration that defines a client secret
    /// When: HostedUIRequestHelper.createSignInURL is invoked with cognito oidc parameters
    /// Then: A URL is generated that contains all the cognito oidc parameters in url query parameters
    func testCreateSignInURL_withCognitoOIDCParametersInOptions_shouldContainOIDCParametersInURLQueryParams() throws {
        createConfiguration(clientSecret: "clientSecret")
        let signInURL = try HostedUIRequestHelper.createSignInURL(
            state: "state",
            proofKey: "proofKey",
            userContextData: nil,
            configuration: configuration,
            options: .init(
                scopes: [],
                providerInfo: .init(authProvider: nil, idpIdentifier: nil),
                presentationAnchor: nil,
                preferPrivateSession: false,
                nonce: "nonce",
                language: "en",
                loginHint: "username",
                prompt: [.login, .consent],
                resource: "http://localhost"
            )
        )

        guard let urlComponents = URLComponents(url: signInURL, resolvingAgainstBaseURL: false) else {
            XCTFail("Failed to get URL components from \(signInURL)")
            return
        }

        XCTAssertEqual("nonce", urlComponents.queryItems?.first(where: { $0.name == "nonce"})?.value)
        XCTAssertEqual("en", urlComponents.queryItems?.first(where: { $0.name == "lang"})?.value)
        XCTAssertEqual("username", urlComponents.queryItems?.first(where: { $0.name == "login_hint"})?.value)
        XCTAssertEqual("login consent", urlComponents.queryItems?.first(where: { $0.name == "prompt"})?.value)
        XCTAssertEqual("http://localhost", urlComponents.queryItems?.first(where: { $0.name == "resource"})?.value)
    }
}
