//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AmplifyAuthCredentialStoreBehavior {
    func saveCredential(_ credential: AWSCognitoAuthCredential) throws
    func retrieveCredential() throws -> AWSCognitoAuthCredential?
    func deleteCredential() throws
}

protocol AmplifyAuthCredentialStoreProvider {
    func getCredentialStore() -> CredentialStoreBehavior
}
