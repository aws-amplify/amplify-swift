//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The configuration-change rule of `AWSCognitoAuthCredentialStore.init`, as a decision the Cognito client's default
/// session also runs: `.default` uses this store's record, so both carry
/// and delete exactly the same records. The store's `restoreCredentialsOnConfigurationChanges` runs the decision.
package extension AWSCognitoAuthCredentialStore {

    /// What the store does to the saved login when it starts under a configuration other than the one it last ran
    /// with (the `authConfiguration` item).
    enum ConfigurationChange: Equatable, Sendable {
        /// Nothing to do: no previous configuration, the same configuration with a user pool, or a change that keeps
        /// the record's key (only the app client changed, with the same pools: the key has no client ID).
        case unchanged
        /// Copy the record at `fromAccount` to `toAccount`, as its bytes are, and keep the old one: a user pool added
        /// to an identity-pool-only configuration, or an identity pool added, changed or removed under the same user
        /// pool, app client and region. The two accounts can be the same (an identity-pool-only configuration started
        /// again, or a change outside the key), and the plugin then writes the record over itself.
        case carry(fromAccount: String, toAccount: String)
        /// Delete the record at `account`, the previous configuration's: any other change of the key. By construction
        /// `account` is `sessionAccount(for: previous)`, the account `removeSession(for: previous)` removes.
        case clear(account: String, previous: AuthConfiguration)
    }

    /// The account of the item holding the configuration the store last ran with.
    static let authConfigurationAccount = "authConfiguration"

    /// The account of the saved login under `configuration`: `amplify.<user pool ID>.<identity pool ID>.session`,
    /// with only the pools configured.
    static func sessionAccount(for configuration: AuthConfiguration) -> String {
        "\(storeKey(for: configuration)).\(sessionKey)"
    }

    /// The decision the store makes at start, from the configuration it last ran with (`nil`: none, or one it could
    /// not read) to the current one.
    ///
    /// - A previous configuration with no user pool, and the same identity pool as the current one: `.carry`.
    /// - A different configuration with the same user pool, app client and region: `.carry`.
    /// - Any other different configuration whose record's key differs: `.clear`.
    /// - Otherwise `.unchanged`.
    static func configurationChange(
        from previous: AuthConfiguration?,
        to current: AuthConfiguration
    ) -> ConfigurationChange {
        guard let previous else {
            return .unchanged
        }
        let oldNameSpace = sessionAccount(for: previous)
        let newNameSpace = sessionAccount(for: current)

        let oldUserPoolConfiguration = previous.getUserPoolConfiguration()
        let oldIdentityPoolConfiguration = previous.getIdentityPoolConfiguration()
        let newIdentityConfigData = current.getIdentityPoolConfiguration()
        let newUserPoolConfiguration = current.getUserPoolConfiguration()

        /// Migrate if
        ///  - Old User Pool Config didn't exist
        ///  - New Identity Config Data exists
        ///  - Old Identity Pool Config == New Identity Pool Config
        if oldUserPoolConfiguration == nil &&
            newIdentityConfigData != nil &&
            oldIdentityPoolConfiguration == newIdentityConfigData {
            return .carry(fromAccount: oldNameSpace, toAccount: newNameSpace)
        /// Migrate if
        ///  - Old config and new config are different
        ///  - Old Userpool Existed
        ///  - Old and new user pool namespacing is the same
        } else if previous != current &&
                    oldUserPoolConfiguration != nil &&
                    UserPoolConfigurationData.isNamespacingEqual(
                        lhs: oldUserPoolConfiguration,
                        rhs: newUserPoolConfiguration
                    ) {
            return .carry(fromAccount: oldNameSpace, toAccount: newNameSpace)
        } else if previous != current &&
                    oldNameSpace != newNameSpace {
            return .clear(account: oldNameSpace, previous: previous)
        }
        return .unchanged
    }

    /// The bytes the store writes to `authConfigurationAccount` for `configuration`: its JSON, with a default
    /// `JSONEncoder`, which does not fix the order of the keys, so two encodings may differ in bytes.
    ///
    /// - Throws: `EngineCredentialStoreError.codingError` if it cannot be encoded.
    static func encodeAuthConfiguration(_ configuration: AuthConfiguration) throws -> Data {
        do {
            return try JSONEncoder().encode(configuration)
        } catch {
            throw EngineCredentialStoreError.codingError("Error occurred while encoding credentials", error)
        }
    }

    /// The configuration the bytes of `authConfigurationAccount` hold.
    ///
    /// - Throws: `EngineCredentialStoreError.codingError` if they are not one.
    static func decodeAuthConfiguration(_ data: Data) throws -> AuthConfiguration {
        do {
            return try JSONDecoder().decode(AuthConfiguration.self, from: data)
        } catch {
            throw EngineCredentialStoreError.codingError("Error occurred while decoding credentials", error)
        }
    }
}
