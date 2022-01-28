//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


enum CredentialStoreState: State {

    case notConfigured

    case migratingLegacyStore(AuthConfiguration)

    case loadingStoredCredentials(AuthConfiguration)

    case credentialsLoaded(CognitoCredentials?)

}

extension CredentialStoreState {
    var type: String {
        switch self {
        case .notConfigured: return "CredentialStoreState.notConfigured"
        case .migratingLegacyStore: return "CredentialStoreState.migratingLegacyStore"
        case .loadingStoredCredentials: return "CredentialStoreState.loadingStoredCredentials"
        case .credentialsLoaded: return "CredentialStoreState.credentialsLoaded"
        }
    }
}

