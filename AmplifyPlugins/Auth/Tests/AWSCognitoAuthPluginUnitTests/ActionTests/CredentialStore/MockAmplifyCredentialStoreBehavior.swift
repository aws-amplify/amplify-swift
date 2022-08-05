//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@testable import AWSCognitoAuthPlugin
import AWSPluginsCore

class MockAmplifyCredentialStoreBehavior: AmplifyAuthCredentialStoreBehavior {

    typealias Migrationhandler = () -> Void
    typealias SaveCredentialHandler = (Codable) throws -> Void
    typealias GetCredentialHandler = () throws -> (Codable)
    typealias ClearCredentialHandler = () throws -> Void

    let migrationCompleteHandler: Migrationhandler?
    let saveCredentialHandler: SaveCredentialHandler?
    let getCredentialHandler: GetCredentialHandler?
    let clearCredentialHandler: ClearCredentialHandler?

    init(migrationCompleteHandler: Migrationhandler? = nil,
         saveCredentialHandler: SaveCredentialHandler? = nil,
         getCredentialHandler: GetCredentialHandler? = nil,
         clearCredentialHandler: ClearCredentialHandler? = nil) {
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
            throw KeychainStoreError.unknown("", nil)
        }
        return credentials as! AmplifyCredentials
    }

    func deleteCredential() throws {
        try clearCredentialHandler?()
    }

    func getCredentialStore() -> KeychainStoreBehavior {
        return MockKeychainStoreBehavior(data: "mock")
    }

    func saveDevice(_ deviceMetadata: DeviceMetadata, for username: String) throws {

    }

    func retrieveDevice(for username: String) throws -> DeviceMetadata {
        DeviceMetadata.noData
    }

    func removeDevice(for username: String) throws {

    }

    func saveASFDevice(_ deviceId: String, for username: String) throws {

    }

    func retrieveASFDevice(for username: String) throws -> String {
        return ""
    }

    func removeASFDevice(for username: String) throws {

    }
}
