//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSCognitoAuthCredentialStore {

    private let service = "com.amplify.credentialStore"
    private let authConfiguration: AuthConfiguration
    private let keychain: CredentialStoreBehavior

    init(authConfiguration: AuthConfiguration, accessGroup: String? = nil) {
        self.authConfiguration = authConfiguration
        self.keychain = AmplifyKeychain(service: service, accessGroup: accessGroup)
    }

    private func buildAuthCredentialStoreKey() throws -> String {
        let prefix = "amplify."
        var suffix = ""
        
        switch authConfiguration {
        case .userPools(let userPoolConfigurationData):
            suffix = userPoolConfigurationData.poolId
        case .identityPools(let identityPoolConfigurationData):
            suffix = identityPoolConfigurationData.poolId
        case .userPoolsAndIdentityPools(let userPoolConfigurationData, let identityPoolConfigurationData):
            suffix = userPoolConfigurationData.poolId + "." + identityPoolConfigurationData.poolId
        }
        
        return prefix + suffix
    }

}

extension AWSCognitoAuthCredentialStore: AmplifyAuthCredentialStoreBehavior {
    
    func saveCredential(credential: AWSCognitoAuthCredential) throws {
        let authCredentialStoreKey = try buildAuthCredentialStoreKey()
        let encodedCredentials = try encode(object: credential)
        try keychain.set(encodedCredentials, key: authCredentialStoreKey)
    }

    func retrieveCredential() throws -> AWSCognitoAuthCredential? {
        let authCredentialStoreKey = try buildAuthCredentialStoreKey()
        do {
            let authCredentialData = try keychain.getData(authCredentialStoreKey)
            let awsCredential: AWSCognitoAuthCredential = try decode(data: authCredentialData)
            return awsCredential
        } catch AmplifyKeychainError.itemNotFound {
            return nil
        }
    }

    func deleteCredential() throws {
        let authCredentialStoreKey = try buildAuthCredentialStoreKey()
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
extension AWSCognitoAuthCredentialStore {
    
    fileprivate func encode<T: Codable>(object: T) throws -> Data {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(object)
        } catch let error {
            throw AmplifyKeychainError.codingError("Error occurred while encoding AWSCredentials", error)
        }
    }

    fileprivate func decode<T: Decodable>(data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            let data = try decoder.decode(T.self, from: data)

            return data
        } catch let error {
            throw AmplifyKeychainError.codingError("Error occurred while decoding AWSCredentials", error)
        }
    }
    
}
