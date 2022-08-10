//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import Amplify

struct CredentialEnvironment: Environment, LoggerProvider  {
    let authConfiguration: AuthConfiguration
    let credentialStoreEnvironment: CredentialStoreEnvironment
    let logger: Logger
}

protocol CredentialStoreEnvironment: Environment {
    typealias AmplifyAuthCredentialStoreFactory = () -> AmplifyAuthCredentialStoreBehavior
    typealias KeychainStoreFactory = (_ service: String) -> KeychainStoreBehavior

    var amplifyCredentialStoreFactory: AmplifyAuthCredentialStoreFactory { get }
    var legacyKeychainStoreFactory: KeychainStoreFactory { get }
    var eventIDFactory: EventIDFactory { get }
}

struct BasicCredentialStoreEnvironment: CredentialStoreEnvironment {

    typealias AmplifyAuthCredentialStoreFactory = () -> AmplifyAuthCredentialStoreBehavior
    typealias KeychainStoreFactory = (_ service: String) -> KeychainStoreBehavior

    // Required
    let amplifyCredentialStoreFactory: AmplifyAuthCredentialStoreFactory
    let legacyKeychainStoreFactory: KeychainStoreFactory

    // Optional
    let eventIDFactory: EventIDFactory

    init(amplifyCredentialStoreFactory: @escaping AmplifyAuthCredentialStoreFactory,
         legacyKeychainStoreFactory: @escaping KeychainStoreFactory,
         eventIDFactory: @escaping EventIDFactory = UUIDFactory.factory) {
        self.amplifyCredentialStoreFactory = amplifyCredentialStoreFactory
        self.legacyKeychainStoreFactory = legacyKeychainStoreFactory
        self.eventIDFactory = eventIDFactory
    }
}
