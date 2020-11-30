//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
import AWSPluginsCore

extension StorageEngine {

    func startSync(completion: @escaping DataStoreCallback<Void>) {
        syncEngineStartSerialQueue.async {
            guard let api = self.tryGetAPIPlugin() else {
                self.log.info("Unable to find suitable API plugin for syncEngine. syncEngine will not be started")
                completion(.failure(.configuration("Unable to find suitable API plugin for syncEngine. syncEngine will not be started",
                                                   "Ensure the API category has been setup and configured for your project", nil)))
                return
            }

            let authPluginRequired = self.requiresAuthPlugin(api: api)

            guard authPluginRequired else {
                if !self.syncEngineCalledStart {
                    self.syncEngineCalledStart = true
                    self.syncEngine?.start(api: api, auth: nil)
                }
                completion(.successfulVoid)
                return
            }

            guard let auth = self.tryGetAuthPlugin() else {
                self.log.warn("Unable to find suitable Auth plugin for syncEngine. Models require auth")
                completion(.failure(.configuration("Unable to find suitable Auth plugin for syncEngine. Models require auth",
                                                   "Ensure the Auth category has been setup and configured for your project", nil)))
                return
            }
            if !self.syncEngineCalledStart {
                self.syncEngineCalledStart = true
                self.syncEngine?.start(api: api, auth: auth)
            }
            completion(.successfulVoid)
        }
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

    private func requiresAuthPlugin(api: APICategoryGraphQLBehavior?) -> Bool {
        let containsAuthEnabledSyncableModels = ModelRegistry.modelSchemas.contains {
            $0.isSyncable && $0.hasAuthenticationRules
        }

        if containsAuthEnabledSyncableModels,
           let apiCategoryAuthProviderBehavior = api as? APICategoryAuthProviderFactoryBehavior,
           apiCategoryAuthProviderBehavior.apiAuthProviderFactory().oidcAuthProvider() != nil {
            if tryGetAuthPlugin() != nil {
                log.warn(
                    """
                    Detected OIDC Auth Provider & Auth Plugin Category available.
                    This is not a supported use case.
                    """)
            }
            return false
        }

        return containsAuthEnabledSyncableModels
    }
}
