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

    /// The user secure storage preferences for access group
    let secureStoragePreferences: AWSCognitoSecureStoragePreferences?

    public internal(set) var jsonConfiguration: JSONValue?

    /// Lock guarding `_cachedSession` for thread-safe access.
    let cachedSessionLock = NSLock()

    /// Backing storage for the cached auth session. Access through `cachedSession` instead.
    var _cachedSession: AWSAuthCognitoSession?

    /// An in-memory cache of the most recently fetched auth session.
    ///
    /// When `fetchAuthSession` is called without `forceRefresh` and the cached tokens are still
    /// valid (not within the 2-minute expiry buffer), the cached session is returned immediately,
    /// bypassing the `TaskQueue`. This eliminates ~300-1000ms of serialization overhead during
    /// concurrent token fetches at app startup. The cache is cleared on `signOut()`.
    var cachedSession: AWSAuthCognitoSession? {
        get {
            cachedSessionLock.lock()
            defer { cachedSessionLock.unlock() }
            return _cachedSession
        }
        set {
            cachedSessionLock.lock()
            defer { cachedSessionLock.unlock() }
            _cachedSession = newValue
        }
    }

    func clearCachedSession() {
        cachedSession = nil
    }

    /// The unique key of the plugin within the auth category.
    public var key: PluginKey {
        return "awsCognitoAuthPlugin"
    }

    /// Instantiates an instance of the AWSCognitoAuthPlugin with optional custom network
    /// preferences and optional custom secure storage preferences
    /// - Parameters:
    ///   - networkPreferences: network preferences
    ///   - secureStoragePreferences: secure storage preferences
    public init(
        networkPreferences: AWSCognitoNetworkPreferences? = nil,
        secureStoragePreferences: AWSCognitoSecureStoragePreferences = AWSCognitoSecureStoragePreferences()
    ) {
        self.networkPreferences = networkPreferences
        self.secureStoragePreferences = secureStoragePreferences
    }
}
