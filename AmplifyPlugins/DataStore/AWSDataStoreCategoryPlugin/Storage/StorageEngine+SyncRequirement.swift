//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
import AWSPluginsCore

extension StorageEngine {

    func startSync(completion: @escaping DataStoreCallback<Void>) {
        guard let api = tryGetAPIPlugin() else {
            log.info("Unable to find suitable API plugin for syncEngine. syncEngine will not be started")
            completion(.failure(.configuration("Unable to find suitable API plugin for syncEngine. syncEngine will not be started",
                                               "Ensure the API category has been setup and configured for your project", nil)))
            return
        }

        let authPluginRequired = requiresAuthPlugin()

        guard authPluginRequired else {
            syncEngine?.start(api: api, auth: nil)
            completion(.successfulVoid)
            return
        }

        guard let auth = tryGetAuthPlugin() else {
            log.warn("Unable to find suitable Auth plugin for syncEngine. Models require auth")
            completion(.failure(.configuration("Unable to find suitable Auth plugin for syncEngine. Models require auth",
                                               "Ensure the Auth category has been setup and configured for your project", nil)))
            return
        }
        syncEngine?.start(api: api, auth: auth)
        completion(.successfulVoid)
    }

    private func tryGetAPIPlugin() -> APICategoryGraphQLBehavior? {
        do {
            return try Amplify.API.getPlugin(for: validAPIPluginKey)
        } catch {
            return nil
        }
    }

    private func tryGetAuthPlugin() -> AuthCategoryBehavior? {
        do {
            return try Amplify.Auth.getPlugin(for: validAuthPluginKey)
        } catch {
            return nil
        }
    }

    private func requiresAuthPlugin() -> Bool {
        let modelsRequireAuthPlugin = ModelRegistry.modelSchemas.contains {
            $0.isSyncable && $0.hasAuthenticationRules && $0.authRules.requireAuthPlugin
        }
        return modelsRequireAuthPlugin
    }
}

internal extension AuthRule {
    var requiresAuthPlugin: Bool {
        switch provider {
        // OIDC, Function and API key providers don't need
        // Auth plugin
        case .oidc, .function, .apiKey, .none:
            return false
        case .userPools, .iam:
            return true
        }
    }
}

internal extension AuthRules {
    /// Convenience method to check whether we need Auth plugin
    /// - Returns: true  If **any** of the rules uses a provider that requires the Auth plugin
    var requireAuthPlugin: Bool {
        contains { $0.requiresAuthPlugin }
    }
}
