//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

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

    var taskQueue: TaskQueue<Any>!

    var httpClientEngineProxy: HttpClientEngineProxy?

    // var authRuntimeHandlers: AuthRuntimeBehavior
    
    @_spi(InternalAmplifyConfiguration)
    internal(set) public var jsonConfiguration: JSONValue?

    /// The unique key of the plugin within the auth category.
    public var key: PluginKey {
        return "awsCognitoAuthPlugin"
    }
        
    /// Closure to retrieve client metadata used during credentials refresh.
    let clientMetadataOnCredentialsRefresh: ((SignedInDataOnRefresh) async -> [String: String])?

    /// Instantiates an instance of the AWSCognitoAuthPlugin.
    public init(clientMetadataOnCredentialsRefresh: ((SignedInDataOnRefresh) async -> [String: String])? = nil) {
        self.clientMetadataOnCredentialsRefresh = clientMetadataOnCredentialsRefresh
    }
}

public struct SignedInDataOnRefresh {
    let userId: String
    let username: String
}
