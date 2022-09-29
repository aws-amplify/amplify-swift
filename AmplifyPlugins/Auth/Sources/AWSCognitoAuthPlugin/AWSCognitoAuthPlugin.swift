//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public final class AWSCognitoAuthPlugin: AWSCognitoAuthPluginBehavior {

    var authEnvironment: AuthEnvironment!

    var authStateMachine: AuthStateMachine!

    var credentialStoreStateMachine: CredentialStoreStateMachine!

     /// A queue that regulates the execution of operations.
    var queue: OperationQueue!

    /// Configuration for the auth plugin
    var authConfiguration: AuthConfiguration!

    /// Handles different auth event send through hub
    var hubEventHandler: AuthHubEventBehavior!

    var analyticsHandler: UserPoolAnalyticsBehavior!

    /// The unique key of the plugin within the auth category.
    public var key: PluginKey {
        return "awsCognitoAuthPlugin"
    }

    /// Instantiates an instance of the AWSCognitoAuthPlugin.
    public init() {
    }
}
