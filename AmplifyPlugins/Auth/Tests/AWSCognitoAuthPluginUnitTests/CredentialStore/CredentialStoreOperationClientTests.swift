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

    var credentialClient: CredentialStoreStateBehavior!

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

    func testDeviceDataSuccess() async throws {
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

    func testMultipleSuccess() async throws {
        await withThrowingTaskGroup(of: Void.self, body: { group in
            for _ in 1...100 {
                group.addTask {
                    let deviceId = "someDeviceID-\(UUID().uuidString)"
                    let username = "someUsername-\(UUID().uuidString)"
                    // Store
                    try await self.credentialClient.storeData(data: .asfDeviceId(deviceId, username))

                    // Fetch
                    let fetchedId = try await self.credentialClient.fetchData(type: .asfDeviceId(username: username))
                    switch fetchedId {
                    case .asfDeviceId(let fetchedId, let fetchedUsername):
                        XCTAssertEqual(deviceId, fetchedId)
                        XCTAssertEqual(username, fetchedUsername)
                    default:
                        XCTFail("Should return asfdevice")
                    }

                    // Delete
                    try await self.credentialClient.deleteData(type: .asfDeviceId(username: username))

                    // Fetch
                    do {
                        _ = try await self.credentialClient.fetchData(
                            type: .asfDeviceId(username: username)
                        )
                        XCTFail("Expected error on initial fetch")
                    } catch {}
                }
            }
        })
    }

    func testMultipleFailuresDuringFetch() async throws {
        await withThrowingTaskGroup(of: Void.self, body: { group in
            for _ in 1...100 {
                group.addTask {
                    let deviceId = "someDeviceID-\(UUID().uuidString)"
                    let username = "someUsername-\(UUID().uuidString)"

                    // Fetch
                    do {
                        _ = try await self.credentialClient.fetchData(
                            type: .asfDeviceId(username: username)
                        )
                        XCTFail("Expected error on initial fetch")
                    } catch {}

                    // Store
                    try await self.credentialClient.storeData(
                        data: .asfDeviceId(deviceId, username)
                    )

                    // Delete
                    try await self.credentialClient.deleteData(
                        type: .asfDeviceId(username: username)
                    )

                    // Fetch
                    do {
                        _ = try await self.credentialClient.fetchData(
                            type: .asfDeviceId(username: username)
                        )
                        XCTFail("Expected error on second fetch")
                    } catch {}
                }
            }
        })
    }
}
