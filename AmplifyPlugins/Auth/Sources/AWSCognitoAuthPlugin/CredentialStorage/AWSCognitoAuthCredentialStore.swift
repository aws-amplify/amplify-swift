//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct AWSCognitoAuthCredentialStore {

    private let service = "com.amplify.credentialStore"
    private let sessionKey = "session"
    private let authConfiguration: AuthConfiguration
    private let keychain: CredentialStoreBehavior

    init(authConfiguration: AuthConfiguration, accessGroup: String? = nil) {
        self.authConfiguration = authConfiguration
        self.keychain = CredentialStore(service: service, accessGroup: accessGroup)
    }

    private func storeKey() -> String {
        let prefix = "amplify"
        var suffix = ""

        switch authConfiguration {
        case .userPools(let userPoolConfigurationData):
            suffix = userPoolConfigurationData.poolId
        case .identityPools(let identityPoolConfigurationData):
            suffix = identityPoolConfigurationData.poolId
        case .userPoolsAndIdentityPools(let userPoolConfigurationData, let identityPoolConfigurationData):
            suffix = "\(userPoolConfigurationData.poolId).\(identityPoolConfigurationData.poolId)"
        }

        return "\(prefix).\(suffix)"
    }

    private func generateSessionKey() -> String {
        return "\(storeKey()).\(sessionKey))"
    }

}

extension AWSCognitoAuthCredentialStore: AmplifyAuthCredentialStoreBehavior {

    func saveCredential(_ credential: AWSCognitoAuthCredential) throws {
        let authCredentialStoreKey = generateSessionKey()
        let encodedCredentials = try encode(object: credential)
        try keychain.set(encodedCredentials, key: authCredentialStoreKey)
    }

    func retrieveCredential() throws -> AWSCognitoAuthCredential? {
        let authCredentialStoreKey = generateSessionKey()
        do {
            let authCredentialData = try keychain.getData(authCredentialStoreKey)
            let awsCredential: AWSCognitoAuthCredential = try decode(data: authCredentialData)
            return awsCredential
        } catch CredentialStoreError.itemNotFound {
            return nil
        }
    }

    func deleteCredential() throws {
        let authCredentialStoreKey = generateSessionKey()
        try keychain.remove(authCredentialStoreKey)
    }

    private func clearAllCredentials() throws {
        try keychain.removeAll()
    }

}

extension AWSCognitoAuthCredentialStore: AmplifyAuthCredentialStoreProvider {

    func getCredentialStore() -> CredentialStoreBehavior {
        return keychain
    }

}

/// Helpers for encode and decoding
private extension AWSCognitoAuthCredentialStore {

    func encode<T: Codable>(object: T) throws -> Data {
        do {
            return try JSONEncoder().encode(object)
        } catch {
            throw CredentialStoreError.codingError("Error occurred while encoding AWSCredentials", error)
        }
    }

    func decode<T: Decodable>(data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw CredentialStoreError.codingError("Error occurred while decoding AWSCredentials", error)
        }
    }

}
