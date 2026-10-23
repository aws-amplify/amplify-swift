//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSPluginsCore
import InternalAmplifyKeychain
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven

// by a single test at a time.

class MockAmplifyCredentialStoreBehavior: AmplifyAuthCredentialStoreBehavior, @unchecked Sendable {

    typealias Migrationhandler = () -> Void
    typealias SaveCredentialHandler = (Codable) throws -> Void
    typealias GetCredentialHandler = () throws -> (Codable)
    typealias ClearCredentialHandler = () throws -> Void

    let migrationCompleteHandler: Migrationhandler?
    let saveCredentialHandler: SaveCredentialHandler?
    let getCredentialHandler: GetCredentialHandler?
    let clearCredentialHandler: ClearCredentialHandler?
    /// Called with the username whenever device metadata or an ASF device id is saved.
    var saveDeviceHandler: ((String) -> Void)?

    init(
        migrationCompleteHandler: Migrationhandler? = nil,
        saveCredentialHandler: SaveCredentialHandler? = nil,
        getCredentialHandler: GetCredentialHandler? = nil,
        clearCredentialHandler: ClearCredentialHandler? = nil
    ) {
        self.migrationCompleteHandler = migrationCompleteHandler
        self.saveCredentialHandler = saveCredentialHandler
        self.getCredentialHandler = getCredentialHandler
        self.clearCredentialHandler = clearCredentialHandler
    }

    func saveCredential(_ credential: AmplifyCredentials) throws {
        try saveCredentialHandler?(credential)
    }

    func retrieveCredential() throws -> AmplifyCredentials {
        guard let credentials = try getCredentialHandler?() else {
            throw EngineCredentialStoreError.unknown("", nil)
        }
        return credentials as! AmplifyCredentials
    }

    func deleteCredential() throws {
        try clearCredentialHandler?()
    }

    func getCredentialStore() -> any KeychainItemStoreBehavior {
        return MockKeychainStoreBehavior(data: "mock")
    }

    func saveDevice(_ deviceMetadata: DeviceMetadata, for username: String) throws {
        saveDeviceHandler?(username)
    }

    func retrieveDevice(for username: String) throws -> DeviceMetadata {
        DeviceMetadata.noData
    }

    func removeDevice(for username: String) throws {

    }

    func saveASFDevice(_ deviceId: String, for username: String) throws {
        saveDeviceHandler?(username)
    }

    func retrieveASFDevice(for username: String) throws -> String {
        return ""
    }

    func removeASFDevice(for username: String) throws {

    }
}
