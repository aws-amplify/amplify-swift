//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import hierarchical_state_machine_swift

protocol CredentialStoreEnvironment: Environment {
    typealias CredentialStoreFactory = () -> AmplifyAuthCredentialStoreBehavior & AmplifyAuthCredentialStoreProvider
    
    var credentialStoreFactory: CredentialStoreFactory { get }
    var eventIDFactory: EventIDFactory { get }
}

struct BasicCredentialStoreEnvironment: CredentialStoreEnvironment {
    
    typealias CredentialStoreFactory = () -> AmplifyAuthCredentialStoreBehavior & AmplifyAuthCredentialStoreProvider
    
    // Required
    let credentialStoreFactory: CredentialStoreFactory
    
    // Optional
    let eventIDFactory: EventIDFactory
    
    init(credentialStoreFactory: @escaping CredentialStoreFactory,
         eventIDFactory: @escaping EventIDFactory = UUIDFactory.factory) {
        self.credentialStoreFactory = credentialStoreFactory
        self.eventIDFactory = eventIDFactory
    }
}
