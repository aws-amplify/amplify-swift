//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin
@testable import AWSPluginsTestCommon
import AWSPluginsCore

class AWSAPICategoryPluginConfigurationTests: XCTestCase {
    let graphQLAPI = "graphQLAPI"
    let apiKey = "apiKey-123"

    var config: AWSAPICategoryPluginConfiguration?
    var endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig?

    override func setUpWithError() throws {
        let apiAuthProviderFactory = APIAuthProviderFactory()
        endpointConfig = try getEndpointConfig(apiName: graphQLAPI, endpointType: .graphQL)

        let interceptorsConfig = AWSAPIEndpointInterceptors(
            endpointName: graphQLAPI,
            apiAuthProviderFactory: apiAuthProviderFactory)

        config = AWSAPICategoryPluginConfiguration(endpoints: [graphQLAPI: endpointConfig!],
                                                   interceptors: [graphQLAPI: interceptorsConfig],
                                                   apiAuthProviderFactory: apiAuthProviderFactory,
                                                   authService: MockAWSAuthService())
    }

    func testThrowsOnMissingConfig() async throws {
        await Amplify.reset()
        let plugin = AWSAPIPlugin()
        try Amplify.add(plugin: plugin)

        let categoryConfig = APICategoryConfiguration(plugins: ["NonExistentPlugin": true])
        let amplifyConfig = AmplifyConfiguration(api: categoryConfig)
        do {
            try Amplify.configure(amplifyConfig)
            XCTFail("Should have thrown a pluginConfigurationError if not supplied with a plugin-specific config.")
        } catch {
            guard case PluginError.pluginConfigurationError = error else {
                XCTFail("Should have thrown a pluginConfigurationError if not supplied with a plugin-specific config.")
                return
            }
        }
    }

    /// Given: a new interceptor conforming to URLRequestInterceptor and an API endpoint name
    /// When: addInterceptor is called
    /// Then: the new interceptor is correctly registered for the given enpoint
    func testAddInterceptors() {
        let apiKeyInterceptor = APIKeyURLRequestInterceptor(apiKeyProvider: BasicAPIKeyProvider(apiKey: apiKey))
        config?.addInterceptor(apiKeyInterceptor, toEndpoint: graphQLAPI)
        XCTAssertEqual(config?.interceptorsForEndpoint(named: graphQLAPI).count, 1)
    }

    /// Given: multiple interceptors conforming to URLRequestInterceptor and an EndpointConfig
    /// When: interceptorsForEndpoint is called with the given EndpointConfig
    /// Then: the registered interceptors are returned
    func testInterceptorsForEndpointWithConfig() throws {
        let apiKeyInterceptor = APIKeyURLRequestInterceptor(apiKeyProvider: BasicAPIKeyProvider(apiKey: apiKey))
        config?.addInterceptor(apiKeyInterceptor, toEndpoint: graphQLAPI)
        config?.addInterceptor(CustomURLInterceptor(), toEndpoint: graphQLAPI)
        let interceptors = try config?.interceptorsForEndpoint(withConfig: endpointConfig!)
        XCTAssertEqual(interceptors!.count, 2)
    }

    /// Given: multiple interceptors conforming to URLRequestInterceptor
    /// When: interceptorsForEndpoint is called with the given EndpointConfig and an authType
    /// Then: the registered interceptors are returned and the auth interceptor is replaced with a
    ///       new interceptor according to provided authType
    func testInterceptorsForEndpointWithConfigAndAuthType() throws {
        let apiKeyInterceptor = APIKeyURLRequestInterceptor(apiKeyProvider: BasicAPIKeyProvider(apiKey: apiKey))
        config?.addInterceptor(apiKeyInterceptor, toEndpoint: graphQLAPI)
        config?.addInterceptor(CustomURLInterceptor(), toEndpoint: graphQLAPI)

        let interceptors = try config?.interceptorsForEndpoint(withConfig: endpointConfig!,
                                                               authType: .amazonCognitoUserPools)

        XCTAssertEqual(interceptors!.count, 2)
        XCTAssertNotNil(interceptors![0] as? AuthTokenURLRequestInterceptor)
        XCTAssertNotNil(interceptors![1] as? CustomURLInterceptor)
    }

    /// Given: an auth interceptor conforming to URLRequestInterceptor
    /// When: interceptorsForEndpoint is called with the given EndpointConfig and an authType
    /// Then: the registered interceptors is replaced with a new interceptor according to
    ///      provided authType
    func testInterceptorForEndpointWithConfigAndAuthType() throws {
        let userPoolInterceptor = AuthTokenURLRequestInterceptor(authTokenProvider: MockTokenProvider())
        config?.addInterceptor(userPoolInterceptor, toEndpoint: graphQLAPI)

        let interceptors = try config?.interceptorsForEndpoint(withConfig: endpointConfig!, authType: .apiKey)

        XCTAssertEqual(interceptors!.count, 1)
        XCTAssertNotNil(interceptors![0] as? APIKeyURLRequestInterceptor)
    }

    // MARK: - Helpers

    func getEndpointConfig(apiName: String, endpointType: AWSAPICategoryPluginEndpointType) throws ->
    AWSAPICategoryPluginConfiguration.EndpointConfig {
        try AWSAPICategoryPluginConfiguration.EndpointConfig(
            name: apiName,
            baseURL: URL(string: "http://myhost")!,
            region: nil,
            authorizationType: AWSAuthorizationType.apiKey,
            endpointType: endpointType,
            apiKey: apiKey,
            apiAuthProviderFactory: APIAuthProviderFactory())
    }

    struct CustomURLInterceptor: URLRequestInterceptor {
        func intercept(_ request: URLRequest) throws -> URLRequest {
            request
        }
    }

    struct MockTokenProvider: AuthTokenProvider {
        func getToken() -> Result<String, AuthError> {
            .success("token")
        }
        
        func getUserPoolAccessToken(completion: @escaping (Result<String, AuthError>) -> Void) {
            completion(.success("token"))
        }
        
        func getUserPoolAccessToken() async throws -> String {
            "token"
        }
    }

}
