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

            // Fall back to the plugin configuration if a determination cannot be made from the auth rules.
            // This occurs for single auth mode use cases, where provider information is not present in the auth rules
            if let awsAPIInfo = apiPlugin as? AWSAPIInformation {
                do {
                    return try awsAPIInfo.defaultAuthType().requiresAuthPlugin
                } catch {
                    log.error(error: error)
                }
            }

            log.error("""
                Could not determine whether auth plugin is required or not. The auth rules present
                may be missing provider information. When this happens, the API Plugin is used to determine
                whether the default auth type requires the auth plugin (used for single auth model endpoints).
            """)

            // It would be quite impossible to fall back to this scenario where the auth type cannot be determined
            // from both the providers from the auth rules and the default endpoint's auth type. However, in such a
            // case, say there are multiple default APIs configured and the default endpoint could not be found, so
            // the follow logic maintains the previous behavior.
            let apiAuthProvider = (apiPlugin as APICategoryAuthProviderFactoryBehavior).apiAuthProviderFactory()
            if apiAuthProvider.oidcAuthProvider() != nil {
                return false
            }
            // There are auth rules and no ODIC provider on the API plugin, then return true.
            return true
        }

        return modelsRequireAuthPlugin
    }
}

internal extension AuthRule {
    var requiresAuthPlugin: Bool? {
        guard let provider = self.provider else {
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
    /// - Returns: true  If **any** of the rules uses a provider that requires the Auth plugin, `nil` otherwise
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
