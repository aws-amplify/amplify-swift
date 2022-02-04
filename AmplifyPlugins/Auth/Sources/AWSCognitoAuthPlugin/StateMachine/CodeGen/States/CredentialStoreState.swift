//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum CredentialStoreState: State {

    case notConfigured

    case migratingLegacyStore

    case loadingStoredCredentials

    case storingCredentials

    case clearingCredentials

    case idle(CognitoCredentials?)

    case error(CredentialStoreError)

}

extension CredentialStoreState {
    var type: String {
        switch self {
        case .notConfigured: return "CredentialStoreState.notConfigured"
        case .migratingLegacyStore: return "CredentialStoreState.migratingLegacyStore"
        case .loadingStoredCredentials: return "CredentialStoreState.loadingStoredCredentials"
        case .storingCredentials: return "CredentialStoreState.storingCredentials"
        case .clearingCredentials: return "CredentialStoreState.clearingCredentials"
        case .idle: return "CredentialStoreState.idle"
        case .error: return "CredentialStoreState.error"
        }
    }
}
