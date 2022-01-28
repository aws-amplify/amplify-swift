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
    typealias SaveCredentialHandler = (CognitoCredentials) -> Void
    typealias GetCredentialHandler = () -> (CognitoCredentials?)
        
    let migrationCompleteHandler: Migrationhandler?
    let saveCredentialHandler: SaveCredentialHandler?
    let getCredentialHandler: GetCredentialHandler?

    init(migrationCompleteHandler: Migrationhandler? = nil,
         saveCredentialHandler:  SaveCredentialHandler? = nil,
         getCredentialHandler: GetCredentialHandler? = nil)
    {
        self.migrationCompleteHandler = migrationCompleteHandler
        self.saveCredentialHandler = saveCredentialHandler
        self.getCredentialHandler = getCredentialHandler
    }
    
    func saveCredential(_ credential: CognitoCredentials) throws {
        saveCredentialHandler?(credential)
    }
    
    func retrieveCredential() throws -> CognitoCredentials? {
        return getCredentialHandler?()
    }

    func deleteCredential() throws {
        migrationCompleteHandler?()
    }

    func getCredentialStore() -> CredentialStoreBehavior {
        return MockCredentialStoreBehavior(data: "mock")
    }

}
