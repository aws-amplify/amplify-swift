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

    func tryStartSync() {
        guard let api = tryGetAPIPlugin() else {
            log.info("Unable to find suitable API plugin for syncEngine. syncEngine will not be started")
            return
        }

        let authPluginRequired = requiresAuthPlugin()

        guard authPluginRequired else {
            syncEngine?.start(api: api, auth: nil)
            return
        }

        guard let auth = tryGetAuthPlugin() else {
            log.warn("Unable to find suitable Auth plugin for syncEngine. Models require auth")
            return
        }

        isSignedIn(auth: auth) { result in
            switch result {
            case .success(let isSignedIn):
                if isSignedIn {
                    self.syncEngine?.start(api: api, auth: auth)
                } else {
                    self.waitForAuthSignedIn(api: api, auth: auth)
                }
            case .failure(let authError):
                self.log.error("Unable to check if user is signed in, error: \(authError)")
            }
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

    private func requiresAuthPlugin() -> Bool {
        let containsAuthEnabledSyncableModels = ModelRegistry.models.contains {
            $0.schema.isSyncable && $0.schema.hasAuth
        }

        return containsAuthEnabledSyncableModels
    }

    private func isSignedIn(auth: AuthCategoryBehavior, onComplete: @escaping (Result<Bool, AuthError>) -> Void) {
        _ = auth.fetchAuthSession(options: nil) { event in
            switch event {
            case .success(let authSession):
                onComplete(.success(authSession.isSignedIn))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }

    private func waitForAuthSignedIn(api: APICategoryGraphQLBehavior, auth: AuthCategoryBehavior) {
        log.debug("\(#function) Amplify.Hub.listen to Auth.signedIn event")
        guard signInListener == nil else {
            log.debug("\(#function) Already listening to Auth.signedIn event")
            return
        }
        let filter = HubFilters.forEventName(HubPayload.EventName.Auth.signedIn)
        signInListener = Amplify.Hub.listen(to: .auth, isIncluded: filter) { _ in
            self.syncEngine?.start(api: api, auth: auth)
            self.waitForAuthSignedOut(api: api, auth: auth)
            self.removeSignInListener()
        }
    }

    private func waitForAuthSignedOut(api: APICategoryGraphQLBehavior, auth: AuthCategoryBehavior) {
        log.debug("\(#function) Amplify.Hub.listen to Auth.signedOut event")
        guard signOutListener == nil else {
            log.debug("\(#function) Already listening to Auth.signedOut event")
            return
        }
        let filter = HubFilters.forEventName(HubPayload.EventName.Auth.signedOut)
        signOutListener = Amplify.Hub.listen(to: .auth, isIncluded: filter) { _ in
            Amplify.DataStore.clear { result in
                switch result {
                case .success:
                    self.waitForAuthSignedIn(api: api, auth: auth)
                case .failure(let dataStoreError):
                    self.log.warn("Unable to clear on SignOut, error: \(dataStoreError)")
                }
            }
            self.removeSignOutListener()
        }
    }

    private func removeSignInListener() {
        if let listener = signInListener {
            Amplify.Hub.removeListener(listener)
        }
    }

    private func removeSignOutListener() {
        if let listener = signOutListener {
            Amplify.Hub.removeListener(listener)
        }
    }
}
