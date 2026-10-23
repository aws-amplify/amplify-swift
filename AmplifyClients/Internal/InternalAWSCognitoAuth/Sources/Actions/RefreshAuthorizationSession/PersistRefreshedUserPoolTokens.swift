//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Stores credentials that hold refreshed user-pool tokens, then runs `followUp`, in that order.
///
/// A session refresh uses it when the user-pool tokens were refreshed but the identity-pool step after
/// them failed. With refresh-token rotation, the refresh invalidated the old refresh token, so the new
/// tokens must be stored as they are when the refresh succeeds (`PersistCredentials`). `followUp` is the
/// failed step's own `InformSessionError`, so the error is reported unchanged, and only once the tokens are
/// stored. A storage failure is logged and does not replace that error.
package struct PersistRefreshedUserPoolTokens: Action {

    package let identifier = "PersistRefreshedUserPoolTokens"

    package let credentials: AmplifyCredentials

    package let followUp: [Action]

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        do {
            let credentialStoreClient = (environment as? AuthEnvironment)?.credentialsClient
            try await credentialStoreClient?.storeData(data: .amplifyCredentials(credentials))
        } catch {
            logError("\(#fileID) Unable to store the refreshed user pool tokens: \(error)", environment: environment)
        }

        for action in followUp {
            await action.execute(withDispatcher: dispatcher, environment: environment)
        }
    }
}

extension PersistRefreshedUserPoolTokens: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "followUp": followUp.map(\.identifier)
        ]
    }
}

extension PersistRefreshedUserPoolTokens: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
