//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@testable import AWSCognitoAuthPlugin

class MockAmplifyCredentialStoreBehavior: AmplifyAuthCredentialStoreBehavior, AmplifyAuthCredentialStoreProvider {

    typealias Migrationhandler = () -> Void
    typealias SaveCredentialHandler = (AWSCognitoAuthCredential) -> Void

    let migrationCompleteHandler: Migrationhandler?
    let saveCredentialHandler: SaveCredentialHandler?

    init(migrationCompleteHandler: Migrationhandler? = nil,
         saveCredentialHandler:  SaveCredentialHandler? = nil)
    {
        self.migrationCompleteHandler = migrationCompleteHandler
        self.saveCredentialHandler = saveCredentialHandler
    }

    func saveCredential(_ credential: AWSCognitoAuthCredential) throws {
        saveCredentialHandler?(credential)
    }

    func retrieveCredential() throws -> AWSCognitoAuthCredential? {
        return nil
    }

    func deleteCredential() throws {
        migrationCompleteHandler?()
    }

    func getCredentialStore() -> CredentialStoreBehavior {
        return MockCredentialStoreBehavior(data: "mock")
    }

}
