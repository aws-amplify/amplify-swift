//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSPluginsCore
import InternalAmplifyCredentials
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin
@testable import AWSPluginsTestCommon

class AWSAPIEndpointInterceptorsTests: XCTestCase {
    let endpointName = "endpointName"
    let apiKey = "apiKey-123456789"
    var config: AWSAuthorizationConfiguration?

    override func setUpWithError() throws {
        config = try AWSAuthorizationConfiguration.makeConfiguration(authType: .apiKey,
                                                                     region: "us-west-2",
                                                                     apiKey: apiKey)
    }

    /// Given: an AWSAPIEndpointInterceptors
    /// When: a new auth interceptor is added
    /// Then: the interceptor is correctly stored
    func testAddAuthInterceptor() throws {
        var interceptorConfig = createAPIInterceptorConfig()

        try interceptorConfig.addAuthInterceptorsToEndpoint(endpointType: .graphQL, authConfiguration: config!)

        XCTAssertEqual(interceptorConfig.preludeInterceptors.count, 1)
        XCTAssertEqual(interceptorConfig.interceptors.count, 0)
        XCTAssertEqual(interceptorConfig.postludeInterceptors.count, 0)
    }

    /// Given: an AWSAPIEndpointInterceptors
    /// When: a new multiple interceptors are added
    /// Then: the interceptors are correctly associated to an endpoint
    func testAddMutipleInterceptors() throws {
        var interceptorConfig = createAPIInterceptorConfig()

        try interceptorConfig.addAuthInterceptorsToEndpoint(endpointType: .graphQL, authConfiguration: config!)
        interceptorConfig.addInterceptor(CustomInterceptor())

        XCTAssertEqual(interceptorConfig.preludeInterceptors.count, 1)
        XCTAssertEqual(interceptorConfig.interceptors.count, 1)
        XCTAssertEqual(interceptorConfig.postludeInterceptors.count, 0)
    }

    func testaddMultipleAuthInterceptors() throws {
        let apiKeyConfig = try AWSAuthorizationConfiguration.makeConfiguration(authType: .apiKey,
                                                                               region: "us-west-2",
                                                                               apiKey: apiKey)

        let awsIAMConfig = try AWSAuthorizationConfiguration.makeConfiguration(authType: .awsIAM,
                                                                               region: "us-west-2",
                                                                               apiKey: apiKey)

        let userPoolConfig = try AWSAuthorizationConfiguration.makeConfiguration(authType: .amazonCognitoUserPools,
                                                                                 region: "us-west-2",
                                                                                 apiKey: nil)

        var interceptorConfig = createAPIInterceptorConfig()
        try interceptorConfig.addAuthInterceptorsToEndpoint(endpointType: .graphQL,
                                                            authConfiguration: apiKeyConfig)
        try interceptorConfig.addAuthInterceptorsToEndpoint(endpointType: .graphQL,
                                                            authConfiguration: awsIAMConfig)

        try interceptorConfig.addAuthInterceptorsToEndpoint(endpointType: .graphQL,
                                                            authConfiguration: userPoolConfig)

        XCTAssertEqual(interceptorConfig.preludeInterceptors.count, 2)
        XCTAssertEqual(interceptorConfig.interceptors.count, 0)
        XCTAssertEqual(interceptorConfig.postludeInterceptors.count, 1)
        XCTAssertNotNil(interceptorConfig.preludeInterceptors[0] as? APIKeyURLRequestInterceptor)
        XCTAssertNotNil(interceptorConfig.preludeInterceptors[1] as? AuthTokenURLRequestInterceptor)
        XCTAssertNotNil(interceptorConfig.postludeInterceptors[0] as? IAMURLRequestInterceptor)
    }

    func testExpiryValidator_Valid() {
        let validToken = Date().timeIntervalSince1970 + 1
        let authService = MockAWSAuthService()
        authService.tokenClaims = ["exp": validToken as AnyObject]
        let interceptorConfig = createAPIInterceptorConfig(authService: authService)
        
        let result = interceptorConfig.expiryValidator("")
        XCTAssertFalse(result)
    }
    
    func testExpiryValidator_Expired() {
        let expiredToken = Date().timeIntervalSince1970 - 1
        let authService = MockAWSAuthService()
        authService.tokenClaims = ["exp": expiredToken as AnyObject]
        let interceptorConfig = createAPIInterceptorConfig(authService: authService)
        
        let result = interceptorConfig.expiryValidator("")
        XCTAssertTrue(result)
    }
    
    // MARK: - Test Helpers

    func createAPIInterceptorConfig(authService: AWSAuthCredentialsProviderBehavior = MockAWSAuthService()) -> AWSAPIEndpointInterceptors {
        return AWSAPIEndpointInterceptors(
            endpointName: endpointName,
            apiAuthProviderFactory: APIAuthProviderFactory(),
            authService: authService)
    }

    struct CustomInterceptor: URLRequestInterceptor {
        func intercept(_ request: URLRequest) throws -> URLRequest {
            return request
        }
    }
}
