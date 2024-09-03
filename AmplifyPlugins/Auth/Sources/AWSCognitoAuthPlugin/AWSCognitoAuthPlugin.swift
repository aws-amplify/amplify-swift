//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

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

    /// The user network preferences for timeout and retry
    let networkPreferences: AWSCognitoNetworkPreferences?

    @_spi(InternalAmplifyConfiguration)
    public internal(set) var jsonConfiguration: JSONValue?

    /// The unique key of the plugin within the auth category.
    public var key: PluginKey {
        return "awsCognitoAuthPlugin"
    }

    /// Instantiates an instance of the AWSCognitoAuthPlugin.
    public init() {
        self.networkPreferences = nil
    }

    /// Instantiates an instance of the AWSCognitoAuthPlugin with custom network preferences
    /// - Parameters:
    ///   - networkPreferences: network preferences
    public init(networkPreferences: AWSCognitoNetworkPreferences) {
        self.networkPreferences = networkPreferences
    }
}
