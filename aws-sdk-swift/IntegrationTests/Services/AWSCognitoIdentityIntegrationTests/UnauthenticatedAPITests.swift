//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSSTS
import AWSCognitoIdentity
import AWSClientRuntime
import ClientRuntime
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse

/// Tests unauthenciated API using AWSCognitoIdentity::getId
class UnauthenticatedAPITests: XCTestCase {
    private let region = "us-east-1"
    private var stsClient: STSClient!
    private var cognitoIdentityClient: CognitoIdentityClient!
    private var cognitoIdentityUnauthenticatedCheckClient: CognitoIdentityClient!

    private var accountID: String!
    private var identityPoolID: String!
    private let identityPoolName = "idpool" + UUID().uuidString.split(separator: "-").first!.lowercased()

    override func setUp() async throws {
        // STS client for getting the account ID, an input parameter for the unauthenticated API, getId().
        stsClient = try STSClient(region: region)

        // CognitoIdentity client for creating & deleting identity pool; requires authentication.
        cognitoIdentityClient = try CognitoIdentityClient(region: region)

        // CognitoIdentity client for calling unauthenticated API against an identity pool.
        let config = try await CognitoIdentityClient.CognitoIdentityClientConfiguration(region: region)
        config.addInterceptorProvider(GetHeadersBeforeTransmitProvider())
        cognitoIdentityUnauthenticatedCheckClient = CognitoIdentityClient(config: config)

        // Create identity pool & save its identity pool ID
        identityPoolID = try await cognitoIdentityClient.createIdentityPool(input: CreateIdentityPoolInput(
            allowUnauthenticatedIdentities: true,
            identityPoolName: identityPoolName
        )).identityPoolId

        // Get and save account ID that has the identity pool
        accountID = try await stsClient.getCallerIdentity(input: GetCallerIdentityInput()).account
    }

    override func tearDown() async throws {
        // Delete the identity pool
        _ = try await cognitoIdentityClient.deleteIdentityPool(input: DeleteIdentityPoolInput(
            identityPoolId: identityPoolID
        ))
    }

    func testUnauthenticatedAPI() async throws {
        // Call unauthenticated API with the client that has an interceptor
        //  that asserts the request is unauthenticated.
        let id = try await cognitoIdentityUnauthenticatedCheckClient.getId(
            input: GetIdInput(accountId: accountID, identityPoolId: identityPoolID)
        ).identityId ?? ""
        // Assert that successful response was returned with a non-empty ID.
        XCTAssertTrue(id.count > 0)
    }
}

// Interceptor & interceptor provider for sanity-checking that request is indeed unauthenticated.
class GetHeadersBeforeTransmit<InputType, OutputType>: Interceptor {
    typealias RequestType = HTTPRequest
    typealias ResponseType = HTTPResponse
    func readBeforeTransmit(context: some AfterSerialization<InputType, RequestType>) async throws {
        // Assert that the request is unauthenticated.
        XCTAssertTrue(!context.getRequest().headers.exists(name: "Authorization"))
    }
}
class GetHeadersBeforeTransmitProvider: HttpInterceptorProvider {
  func create<InputType, OutputType>() -> any Interceptor<InputType, OutputType, HTTPRequest, HTTPResponse> {
    return GetHeadersBeforeTransmit()
  }
}
