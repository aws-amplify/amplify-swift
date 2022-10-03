//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Amplify
@testable import AWSCognitoAuthPlugin

class CredentialStoreOperationClientTests: XCTestCase {

    var credentialClient: CredentialStoreStateBehaviour!

    override func setUp() async throws {
        let credentialEnvironment = CredentialEnvironment(
            authConfiguration: Defaults.makeAuthConfiguration(),
            credentialStoreEnvironment: BasicCredentialStoreEnvironment(
                amplifyCredentialStoreFactory: Defaults.makeAmplifyStore,
                legacyKeychainStoreFactory: Defaults.makeLegacyStore(service:)
            ),
            logger: Amplify.Logging.logger(forCategory: "awsCognitoAuthPluginTest")
        )

        let credentialStateMachine = CredentialStoreStateMachine(
            resolver: CredentialStoreState.Resolver(),
            environment: credentialEnvironment,
            initialState: .idle)

        credentialClient = CredentialStoreOperationClient(
            credentialStoreStateMachine: credentialStateMachine)
    }

    func testSuccess() async throws {
        let deviceId = "someDeviceID"
        let username = "someUsername"
        try await credentialClient.storeData(data: .asfDeviceId(deviceId, username))

        let fetchedId = try await credentialClient.fetchData(type: .asfDeviceId(username: username))
        switch fetchedId {
        case .asfDeviceId(let fetchedId, let fetchedUsername):
            XCTAssertEqual(deviceId, fetchedId)
            XCTAssertEqual(username, fetchedUsername)
        default:
            XCTFail("Should return asfdevice")
        }
    }
}
