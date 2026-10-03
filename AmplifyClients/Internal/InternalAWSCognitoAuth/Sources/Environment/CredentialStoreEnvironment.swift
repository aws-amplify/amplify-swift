//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import InternalAmplifyKeychain

package struct CredentialEnvironment: Environment, LoggerProvider {
    package let authConfiguration: AuthConfiguration
    package let credentialStoreEnvironment: CredentialStoreEnvironment
    package let logger: any EngineScopedLogger

    package init(
        authConfiguration: AuthConfiguration,
        credentialStoreEnvironment: CredentialStoreEnvironment,
        logger: any EngineScopedLogger
    ) {
        self.authConfiguration = authConfiguration
        self.credentialStoreEnvironment = credentialStoreEnvironment
        self.logger = logger
    }
}

package protocol CredentialStoreEnvironment: Environment {
    typealias AmplifyAuthCredentialStoreFactory = @Sendable () -> AmplifyAuthCredentialStoreBehavior
    typealias KeychainStoreFactory = @Sendable (_ service: String) -> any KeychainItemStoreBehavior

    var amplifyCredentialStoreFactory: AmplifyAuthCredentialStoreFactory { get }
    var legacyKeychainStoreFactory: KeychainStoreFactory { get }
    var eventIDFactory: EventIDFactory { get }
}

package extension CredentialStoreEnvironment {
    /// A legacy store for `service`, over the item store `legacyKeychainStoreFactory` builds for it, logging
    /// through `logger`: the caller's, the credential environment's (`CredentialEnvironment.logger`).
    func legacyKeychainStore(_ service: String, logger: any EngineScopedLogger) -> EngineKeychainStore {
        EngineKeychainStore(legacyKeychainStoreFactory(service), logger: logger)
    }
}

package struct BasicCredentialStoreEnvironment: CredentialStoreEnvironment {

    package typealias AmplifyAuthCredentialStoreFactory = @Sendable () -> AmplifyAuthCredentialStoreBehavior
    package typealias KeychainStoreFactory = @Sendable (_ service: String) -> any KeychainItemStoreBehavior

    // Required
    package let amplifyCredentialStoreFactory: AmplifyAuthCredentialStoreFactory
    package let legacyKeychainStoreFactory: KeychainStoreFactory

    // Optional
    package let eventIDFactory: EventIDFactory

    package init(
        amplifyCredentialStoreFactory: @escaping AmplifyAuthCredentialStoreFactory,
        legacyKeychainStoreFactory: @escaping KeychainStoreFactory,
        eventIDFactory: @escaping EventIDFactory = UUIDFactory.factory
    ) {
        self.amplifyCredentialStoreFactory = amplifyCredentialStoreFactory
        self.legacyKeychainStoreFactory = legacyKeychainStoreFactory
        self.eventIDFactory = eventIDFactory
    }
}
