//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


public enum CredentialStoreState: State {

    case notConfigured

    case migratingLegacyStore(AuthConfiguration)

    case loadingStoredCredentials(AuthConfiguration)

    case configuredCredentialStore

}

public extension CredentialStoreState {
    var type: String {
        switch self {
        case .notConfigured: return "CredentialStoreState.notConfigured"
        case .migratingLegacyStore: return "CredentialStoreState.migratingLegacyStore"
        case .loadingStoredCredentials: return "CredentialStoreState.loadingStoredCredentials"
        case .configuredCredentialStore: return "CredentialStoreState.configuredCredentialStore"
        }
    }
}

