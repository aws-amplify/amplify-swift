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

            // When we cannot determine whether auth plugin is required or not from the auth rule's provider
            // information, then check for the existence of the ODIC/function provider. If is is there, this supports
            // use cases where there is a single auth type on the endpoint, which does not require auth plugin, so
            // return false. Existing developers that have not upgraded the CLI and generated the provider information
            // are also supported through the logic below: return false when there is an OIDC/function provider, return
            // true when there are auth rules.
            let apiAuthProvider = (apiPlugin as APICategoryAuthProviderFactoryBehavior).apiAuthProviderFactory()
            if apiAuthProvider.oidcAuthProvider() != nil || apiAuthProvider.functionAuthProvider() != nil {
                return false
            }

            // There are auth rules and no ODIC/function provider on the API plugin, then return true.
            return true
        }

        return modelsRequireAuthPlugin
    }
}

extension AuthRules {

    /// Convenience method to check whether we need Auth plugin
    /// - Returns:
    ///     `true`  If **any** of the rules uses a provider that requires the Auth plugin
    ///     `nil` if a determination cannot be made
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

extension AuthRule {
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
