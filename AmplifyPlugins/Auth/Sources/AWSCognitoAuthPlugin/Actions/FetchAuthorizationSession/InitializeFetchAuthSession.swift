//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

struct InitializeFetchAuthSession: Action {

    let identifier = "InitializeFetchAuthSession"

    let storedCredentials: CognitoCredentials?

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        logVerbose("Starting execution", environment: environment)

        let isSignedIn = storedCredentials?.userPoolTokens != nil
        let identityIdResult: Result<String, AuthError>
        let awsCredentialsResult: Result<AuthAWSCredentials, AuthError>
        let cognitoTokensResult: Result<AuthCognitoTokens, AuthError>
        // TODO: Implement this
        let userSubResult: Result<String, AuthError> = .failure(AuthError.unknown("", nil))

        if let userPoolTokens = storedCredentials?.userPoolTokens {
            cognitoTokensResult = .success(userPoolTokens)
        } else {
            cognitoTokensResult = .failure(
                AuthError.signedOut(AuthPluginErrorConstants.cognitoTokensSignOutError.errorDescription,
                                    AuthPluginErrorConstants.cognitoTokensSignOutError.recoverySuggestion)
            )
        }

        if let identityId = storedCredentials?.identityId {
            identityIdResult = .success(identityId)
        } else {
            let identityIdError = AuthError.service(
                AuthPluginErrorConstants.identityIdSignOutError.errorDescription,
                AuthPluginErrorConstants.identityIdSignOutError.recoverySuggestion,
                AWSCognitoAuthError.invalidAccountTypeException)
            identityIdResult = .failure(identityIdError)
        }

        if let awsCredentials = storedCredentials?.awsCredential {
            awsCredentialsResult = .success(awsCredentials)
        } else {
            let awsCredentialsError = AuthError.service(
                AuthPluginErrorConstants.awsCredentialsSignOutError.errorDescription,
                AuthPluginErrorConstants.awsCredentialsSignOutError.recoverySuggestion,
                AWSCognitoAuthError.invalidAccountTypeException)
            awsCredentialsResult = .failure(awsCredentialsError)
        }

        let session = AWSAuthCognitoSession(isSignedIn: isSignedIn,
                                            userSubResult: userSubResult,
                                            identityIdResult: identityIdResult,
                                            awsCredentialsResult: awsCredentialsResult,
                                            cognitoTokensResult: cognitoTokensResult)

        let event: FetchAuthSessionEvent
        if let _ = storedCredentials?.userPoolTokens {
            event = FetchAuthSessionEvent(eventType: .fetchUserPoolTokens(session))
        } else {
            event = FetchAuthSessionEvent(eventType: .fetchIdentity(session))
        }

        logVerbose("Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
    }
}

extension InitializeFetchAuthSession: DefaultLogger { }

extension InitializeFetchAuthSession: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension InitializeFetchAuthSession: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
