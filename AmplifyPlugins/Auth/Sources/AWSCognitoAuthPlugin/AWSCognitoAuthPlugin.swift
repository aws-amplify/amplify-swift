//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public final class AWSCognitoAuthPlugin: AuthCategoryPlugin {

    var authStateMachine: StateMachine<AuthState, AuthEnvironment>!
    var authStateListenerToken: StateMachine<AuthState, AuthEnvironment>.StateChangeListenerToken!

    var credentialStoreStateMachine: StateMachine<CredentialStoreState, CredentialEnvironment>!

    /// A queue that regulates the execution of operations.
    var queue: OperationQueue!

    /// Configuration for the auth plugin
    var authConfiguration: AuthConfiguration!

    /// The unique key of the plugin within the auth category.
    public var key: PluginKey {
        return "awsCognitoAuthPlugin"
    }

    /// Instantiates an instance of the AWSCognitoAuthPlugin.
    public init() {
    }
}
