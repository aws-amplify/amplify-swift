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

        let authPluginRequired = requiresAuthPlugin(api)

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

    private func tryGetAPIPlugin() -> APICategoryPlugin? {
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

    private func requiresAuthPlugin(_ apiPlugin: APICategoryPlugin) -> Bool {
        let modelsRequireAuthPlugin = ModelRegistry.modelSchemas.contains { schema in
            guard schema.isSyncable && schema.hasAuthenticationRules else {
                return false
            }
            if let rulesRequireAuthPlugin = schema.authRules.requireAuthPlugin {
                return rulesRequireAuthPlugin
            }

#if canImport(AWSAPIPlugin)
            // Fall back to the plugin configuration if a determination cannot be made from the auth rules.
            guard let awsPlugin = apiPlugin as? AWSAPIPlugin else {
                // No determination can be made. Throw error?
                return false
            }
            return awsPlugin.hasAuthPluginRequirement
#else
            return false
#endif
        }
        return modelsRequireAuthPlugin
    }
}

#if canImport(AWSAPIPlugin)
internal extension AWSAPIPlugin {
    var hasAuthPluginRequirement: Bool {
        return pluginConfig.endpoints.values.contains {
            $0.authorizationType.requiresAuthPlugin
        }
    }
}
#endif

internal extension AWSAuthorizationType {
    var requiresAuthPlugin: Bool {
        switch self {
        case .none, .apiKey, .openIDConnect, .function:
            return false
        case .awsIAM, .amazonCognitoUserPools:
            return true
        }
    }
}

internal extension AuthRule {
    var requiresAuthPlugin: Bool? {
        guard let provider = provider else {
            return nil
        }
        switch provider {
        // OIDC, Function and API key providers don't need
        // Auth plugin
        case .oidc, .function, .apiKey:
            return false
        case .userPools, .iam:
            return true
        }
    }
}

internal extension AuthRules {
    /// Convenience method to check whether we need Auth plugin
    /// - Returns: true  If **any** of the rules uses a provider that requires the Auth plugin, `nil` if a determination cannot be made
    var requireAuthPlugin: Bool? {
        for rule in self {
            guard let requiresAuthPlugin = rule.requiresAuthPlugin else {
                return nil
            }
            if requiresAuthPlugin {
                return true
            }
        }
        return false
    }
}
