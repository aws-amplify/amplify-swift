//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

class AuthHubEventHandler: AuthHubEventBehavior {

    var lastSendEventName: HubPayloadEventName?

    init() {
        setupHubEvents()
    }

    func sendUserSignedInEvent() {
        dispatchAuthEvent(HubPayload.EventName.Auth.signedIn)
    }

    func sendUserSignedOutEvent() {
        dispatchAuthEvent(HubPayload.EventName.Auth.signedOut)
    }

    func sendUserDeletedEvent() {
        dispatchAuthEvent(HubPayload.EventName.Auth.userDeleted)
    }

    func sendSessionExpiredEvent() {
        dispatchAuthEvent(HubPayload.EventName.Auth.sessionExpired)
    }

    // swiftlint:disable cyclomatic_complexity
    private func setupHubEvents() {

        _ = Amplify.Hub.listen(to: .auth) {[weak self] payload in
            switch payload.eventName {

            case HubPayload.EventName.Auth.signInAPI:
                guard let event = payload.data as? AWSAuthSignInTask.AmplifyAuthTaskResult,
                    case let .success(result) = event else {
                        return
                }
                self?.handleSignInEvent(result)

            case HubPayload.EventName.Auth.confirmSignInAPI:
                guard let event = payload.data as? AWSAuthConfirmSignInTask.AmplifyAuthTaskResult,
                    case let .success(result) = event else {
                        return
                }
                self?.handleSignInEvent(result)

            case HubPayload.EventName.Auth.webUISignInAPI:
                guard let event = payload.data as? AWSAuthWebUISignInTask.AmplifyAuthTaskResult,
                    case let .success(result) = event else {
                        return
                }
                self?.handleSignInEvent(result)

            case HubPayload.EventName.Auth.socialWebUISignInAPI:
                guard let event = payload.data as? AWSAuthWebUISignInTask.AmplifyAuthTaskResult,
                    case let .success(result) = event else {
                        return
                }
                self?.handleSignInEvent(result)

            case HubPayload.EventName.Auth.deleteUserAPI:
                guard let event = payload.data as? AWSAuthDeleteUserTask.AmplifyAuthTaskResult,
                    case .success = event else {
                        return
                }
                self?.sendUserDeletedEvent()

            case HubPayload.EventName.Auth.signOutAPI:
                guard let event = payload.data as? AWSAuthSignOutTask.AmplifyAuthTaskResult,
                    case .success = event else {
                        return
                }
                self?.sendUserSignedOutEvent()

            case HubPayload.EventName.Auth.fetchSessionAPI:
                guard let event = payload.data as? AWSAuthFetchSessionOperation.OperationResult,
                    case let .success(result) = event else {
                        return
                }
                self?.handleSessionEvent(result)

            default:
                break
            }
        }
    }

    private func handleSignInEvent(_ signInResult: AuthSignInResult) {
        guard signInResult.isSignedIn else {
            return
        }
        sendUserSignedInEvent()
    }

    private func handleSessionEvent(_ sessionResult: AuthSession) {
        guard let tokensProvider = sessionResult as? AuthCognitoTokensProvider,
            case let .failure(authError) = tokensProvider.getCognitoTokens() else {
                return
        }
        guard case .sessionExpired = authError else {
            return
        }
        sendSessionExpiredEvent()
    }

    private func dispatchAuthEvent(_ eventName: String) {
        if eventName != lastSendEventName {
            lastSendEventName = eventName
            Amplify.Hub.dispatch(to: .auth, payload: HubPayload(eventName: eventName))
        }
    }

}
