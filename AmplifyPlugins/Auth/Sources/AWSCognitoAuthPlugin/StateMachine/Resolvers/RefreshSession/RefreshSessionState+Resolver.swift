//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension RefreshSessionState {

    struct Resolver: StateMachineResolver {

        var defaultState: RefreshSessionState = .notStarted

        func resolve(oldState: RefreshSessionState,
                     byApplying event: StateMachineEvent) -> StateResolution<RefreshSessionState> {

            switch oldState {
            case .notStarted:

                if case .refreshCognitoUserPool(let signedInData) = event.isRefreshSessionEvent {
                    let action = RefreshUserPoolTokens(existingSignedIndata: signedInData)
                    return .init(newState: .refreshingUserPoolToken(signedInData), actions: [action])
                }

                if case .refreshCognitoUserPoolWithIdentityId(
                    let signedInData,
                    let identityID) = event.isRefreshSessionEvent {
                    let action = RefreshUserPoolTokens(existingSignedIndata: signedInData)
                    return .init(newState: .refreshingUserPoolTokenWithIdentity(signedInData, identityID),
                                 actions: [action])
                }
                if case .refreshUnAuthAWSCredentials(let identityID) = event.isRefreshSessionEvent {
                    let provider = UnAuthLoginsMapProvider()
                    let action = FetchAuthAWSCredentials(loginsMap: provider.loginsMap,
                                                         identityID: identityID)
                    return .init(newState: .refreshingUnAuthAWSCredentials(identityID),
                                 actions: [action])
                }

                if case .throwError(let error) = event.isRefreshSessionEvent {
                    let action = InformSessionError(error: error)
                    return .init(newState: .error(error), actions: [action])
                }
                return .from(oldState)

            case .refreshingUserPoolToken:

                if case .throwError(let error) = event.isRefreshSessionEvent {
                    let action = InformSessionError(error: error)
                    return .init(newState: .error(error), actions: [action])
                }
                if case .refreshedCognitoUserPool(let signedInData) = event.isRefreshSessionEvent {
                    let credentials = AmplifyCredentials.userPoolOnly(signedInData: signedInData)
                    let action = InformSessionRefreshed(credentials: credentials)
                    return .init(newState: .refreshed(credentials), actions: [action])
                }

                if case .refreshIdentityInfo(let signedInData, _) = event.isRefreshSessionEvent {
                    let action = InitializeFetchAuthSessionWithUserPool(signedInData: signedInData)
                    return .init(newState: .fetchingAuthSessionWithUserPool(.notStarted, signedInData),
                                 actions: [action])
                }
                return .from(oldState)

            case .refreshingUserPoolTokenWithIdentity(_, let identityID):

                if case .throwError(let error) = event.isRefreshSessionEvent {
                    let action = InformSessionError(error: error)
                    return .init(newState: .error(error), actions: [action])
                }
                if case .refreshedCognitoUserPool(let signedInData) = event.isRefreshSessionEvent {
                    let credentials = AmplifyCredentials.userPoolOnly(signedInData: signedInData)
                    let action = InformSessionRefreshed(credentials: credentials)
                    return .init(newState: .refreshed(credentials), actions: [action])
                }
                if case .refreshIdentityInfo(let signedInData, let provider) = event.isRefreshSessionEvent {
                    let action = FetchAuthAWSCredentials(loginsMap: provider.loginsMap,
                                                         identityID: identityID)
                    return .init(newState: .refreshingAWSCredentialsWithUserPoolTokens(
                        signedInData,
                        identityID), actions: [action])
                }
                return .from(oldState)

            case .fetchingAuthSessionWithUserPool(let fetchSessionState, let signedInData):

                if case .throwError(let error) = event.isRefreshSessionEvent {
                    let action = InformSessionError(error: error)
                    return .init(newState: .error(error), actions: [action])
                }
                if case .fetched(let identityID,
                                 let credentials) = event.isAuthorizationEvent {
                    let credentials = AmplifyCredentials.userPoolAndIdentityPool(
                        signedInData: signedInData,
                        identityID: identityID,
                        credentials: credentials)
                    let action = InformSessionRefreshed(credentials: credentials)
                    return .init(newState: .refreshed(credentials), actions: [action])
                }
                let resolver = FetchAuthSessionState.Resolver()
                let resolution = resolver.resolve(oldState: fetchSessionState,
                                                  byApplying: event)
                return .init(newState: .fetchingAuthSessionWithUserPool(
                    resolution.newState,
                    signedInData), actions: resolution.actions)

            case .refreshingUnAuthAWSCredentials:

                if case .throwError(let error) = event.isFetchSessionEvent {
                    let action = InformSessionError(error: error)
                    return .init(newState: .error(error), actions: [action])
                }
                if case .fetchedAWSCredentials(
                    let identityID,
                    let credentials) = event.isFetchSessionEvent {
                    let amplifyCredentials = AmplifyCredentials.identityPoolOnly(
                        identityID: identityID,
                        credentials: credentials)
                    let action = InformSessionRefreshed(credentials: amplifyCredentials)
                    return .init(newState: .refreshed(amplifyCredentials), actions: [action])
                }
                return .from(oldState)

            case .refreshingAWSCredentialsWithUserPoolTokens(let signedInData, _):

                if case .throwError(let error) = event.isFetchSessionEvent {
                    let action = InformSessionError(error: error)
                    return .init(newState: .error(error), actions: [action])
                }
                if case .fetchedAWSCredentials(
                    let identityID,
                    let credentials) = event.isFetchSessionEvent {
                    let amplifyCredentials = AmplifyCredentials.userPoolAndIdentityPool(
                        signedInData: signedInData,
                        identityID: identityID,
                        credentials: credentials)
                    let action = InformSessionRefreshed(credentials: amplifyCredentials)
                    return .init(newState: .refreshed(amplifyCredentials), actions: [action])
                }
                return .from(oldState)

            case .error, .refreshed:
                return .from(oldState)
            }
        }
    }

}
