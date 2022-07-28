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

    func saveCredential(_ credential: Codable) throws {
        try saveCredentialHandler?(credential)
    }

    func retrieveCredential() throws -> Codable {
        guard let credentials = try getCredentialHandler?() else {
            throw KeychainStoreError.unknown("", nil)
        }
        return credentials
    }

    func deleteCredential() throws {
        try clearCredentialHandler?()
    }
}
