//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AmplifyAuthCredentialStoreBehavior {
    func saveCredential(_ credential: CognitoCredentials) throws
    func retrieveCredential() throws -> CognitoCredentials
    func deleteCredential() throws
}

protocol AmplifyAuthCredentialStoreProvider {
    func getCredentialStore() -> CredentialStoreBehavior
}
