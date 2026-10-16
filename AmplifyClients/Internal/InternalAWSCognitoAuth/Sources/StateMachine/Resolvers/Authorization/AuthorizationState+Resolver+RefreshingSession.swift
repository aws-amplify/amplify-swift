//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The `.refreshingSession` state of `AuthorizationState.Resolver`, and the refreshed user-pool tokens a failed
/// refresh keeps.
extension AuthorizationState.Resolver {

    func resolveRefreshingSession(
        existingCredentials: AmplifyCredentials,
        refreshState: RefreshSessionState,
        byApplying event: StateMachineEvent
    ) -> StateResolution<StateType> {
        if case .refreshed(let amplifyCredentials) = event.isAuthorizationEvent {
            let action = PersistCredentials(credentials: amplifyCredentials)
            return .init(
                newState: .storingCredentials(amplifyCredentials),
                actions: [action]
            )
        }

        if case .receivedSessionError(let error) = event.isAuthorizationEvent {
            return .init(newState: .error(.sessionError(error, existingCredentials)))
        }

        if case .throwError(let error) = event.isAuthorizationEvent {
            // An identity-pool step can fail with an authorization error directly
            // (`FetchAuthIdentityId` without an identity client). If the user-pool tokens were
            // refreshed, store them first, then report the same error again: this state then holds
            // the refreshed credentials, so the second report goes straight to `.error`.
            if let refreshedCredentials = Self.refreshedCredentials(
                in: refreshState,
                existingCredentials: existingCredentials
            ) {
                let reportError = BasicAction(identifier: "ReportAuthorizationError") { dispatcher, _ in
                    await dispatcher.send(AuthorizationEvent(eventType: .throwError(error)))
                }
                let action = PersistRefreshedUserPoolTokens(
                    credentials: refreshedCredentials,
                    followUp: [reportError]
                )
                return .init(newState: .refreshingSession(
                    existingCredentials: refreshedCredentials,
                    refreshState
                ), actions: [action])
            }
            return .init(newState: .error(error))
        }
        let resolver = RefreshSessionState.Resolver()
        let resolution = resolver.resolve(oldState: refreshState, byApplying: event)
        if let refreshedCredentials = Self.credentialsKeepingRefreshedTokens(
            from: refreshState,
            to: resolution.newState,
            existingCredentials: existingCredentials
        ) {
            // Store the refreshed tokens before the failure is reported, and carry them into the
            // error state, so that the next refresh uses them.
            let action = PersistRefreshedUserPoolTokens(
                credentials: refreshedCredentials,
                followUp: resolution.actions
            )
            return .init(newState: .refreshingSession(
                existingCredentials: refreshedCredentials,
                resolution.newState
            ), actions: [action])
        }
        return .init(newState: .refreshingSession(
            existingCredentials: existingCredentials,
            resolution.newState
        ), actions: resolution.actions)
    }

    /// The credentials a failed session refresh must keep when its user-pool tokens were refreshed.
    ///
    /// Returns `nil` unless the refresh moved from a state holding refreshed user-pool tokens into an
    /// error, that is, the identity-pool step after `GetTokensFromRefreshToken` failed. With refresh-token
    /// rotation, that call invalidated the old refresh token, so the error state and the credential store
    /// must hold the new tokens, as they do when the refresh succeeds. The identity ID and AWS credentials
    /// stay the existing ones: the failed step did not replace them.
    private static func credentialsKeepingRefreshedTokens(
        from oldState: RefreshSessionState,
        to newState: RefreshSessionState,
        existingCredentials: AmplifyCredentials
    ) -> AmplifyCredentials? {
        switch newState {
        case .error, .fetchingAuthSessionWithUserPool(.error, _):
            return refreshedCredentials(in: oldState, existingCredentials: existingCredentials)
        default:
            return nil
        }
    }

    /// The existing credentials with the refreshed user-pool data of `refreshState`, or `nil` if
    /// `refreshState` holds none: it is not past the user-pool step, it has already failed, or its
    /// user-pool data equals the existing one (only the AWS credentials are being refreshed, or the
    /// refreshed credentials were already kept).
    private static func refreshedCredentials(
        in refreshState: RefreshSessionState,
        existingCredentials: AmplifyCredentials
    ) -> AmplifyCredentials? {
        let refreshedSignedInData: SignedInData
        switch refreshState {
        case .refreshingAWSCredentialsWithUserPoolTokens(let signedInData, _):
            refreshedSignedInData = signedInData
        case .fetchingAuthSessionWithUserPool(let fetchState, let signedInData):
            if case .error = fetchState {
                return nil
            }
            refreshedSignedInData = signedInData
        default:
            return nil
        }

        switch existingCredentials {
        case .userPoolAndIdentityPool(let existingSignedInData, let identityID, let awsCredentials)
            where existingSignedInData != refreshedSignedInData:
            return .userPoolAndIdentityPool(
                signedInData: refreshedSignedInData,
                identityID: identityID,
                credentials: awsCredentials
            )
        case .userPoolOnly(let existingSignedInData) where existingSignedInData != refreshedSignedInData:
            return .userPoolOnly(signedInData: refreshedSignedInData)
        default:
            return nil
        }
    }
}
