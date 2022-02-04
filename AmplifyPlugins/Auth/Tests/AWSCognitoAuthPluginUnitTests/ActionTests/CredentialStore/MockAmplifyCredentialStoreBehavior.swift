//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@testable import AWSCognitoAuthPlugin

class MockAmplifyCredentialStoreBehavior: AmplifyAuthCredentialStoreBehavior, AmplifyAuthCredentialStoreProvider {
    
    typealias Migrationhandler = () -> ()
    typealias SaveCredentialHandler = (CognitoCredentials) throws -> Void
    typealias GetCredentialHandler = () throws -> (CognitoCredentials?)
    typealias ClearCredentialHandler = () throws -> ()
        
    let migrationCompleteHandler: Migrationhandler?
    let saveCredentialHandler: SaveCredentialHandler?
    let getCredentialHandler: GetCredentialHandler?
    let clearCredentialHandler: ClearCredentialHandler?

    init(migrationCompleteHandler: Migrationhandler? = nil,
         saveCredentialHandler:  SaveCredentialHandler? = nil,
         getCredentialHandler: GetCredentialHandler? = nil,
         clearCredentialHandler: ClearCredentialHandler? = nil)
    {
        self.migrationCompleteHandler = migrationCompleteHandler
        self.saveCredentialHandler = saveCredentialHandler
        self.getCredentialHandler = getCredentialHandler
        self.clearCredentialHandler = clearCredentialHandler
    }
    
    func saveCredential(_ credential: CognitoCredentials) throws {
        try saveCredentialHandler?(credential)
    }
    
    func retrieveCredential() throws -> CognitoCredentials? {
        return try getCredentialHandler?()
    }

    func deleteCredential() throws {
        try clearCredentialHandler?()
    }

    func getCredentialStore() -> CredentialStoreBehavior {
        return MockCredentialStoreBehavior(data: "mock")
    }

}
