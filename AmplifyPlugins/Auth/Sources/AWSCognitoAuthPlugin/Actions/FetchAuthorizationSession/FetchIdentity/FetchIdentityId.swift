//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import Foundation
import ClientRuntime

struct FetchIdentityId: Action {

    let identifier = "FetchUnAuthenticatedIdentityId"

    let loginsMap: [String: String]

    init(loginsMap: [String: String] = [:]) {
        self.loginsMap = loginsMap
    }

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let authEnv = environment as? AuthEnvironment,
              let authZEnvironment = authEnv.authorizationEnvironment,
              let client = try? authZEnvironment.cognitoIdentityFactory()
        else {
            let authZError = AuthorizationError.configuration(
                message: AuthPluginErrorConstants.signedInIdentityIdWithNoCIDPError.errorDescription)
            let event = FetchIdentityEvent(eventType: .throwError(authZError))
            dispatcher.send(event)
            return
        }

        let getIdInput = GetIdInput(
            identityPoolId: authZEnvironment.identityPoolConfiguration.poolId,
            logins: loginsMap)

        Task {
            do {
                let response = try await client.getId(input: getIdInput)

                guard let identityId = response.identityId else {
                    let event = FetchAuthSessionEvent(eventType: .throwError(.invalidIdentityID))
                    dispatcher.send(event)
                    return
                }
                let event = FetchAuthSessionEvent(eventType: .fetchedIdentityID(identityId))
                logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                dispatcher.send(event)
            } catch {

                let event: FetchAuthSessionEvent
                if isNotAuthorizedError(error) {
                    event = FetchAuthSessionEvent(eventType: .throwError(.notAuthorized))
                } else {
                    event = FetchAuthSessionEvent(eventType: .throwError(.service(error)))
                }
                logVerbose("\(#fileID) Sending event \(event.type)",
                           environment: environment)
                dispatcher.send(event)
            }
        }
    }

    func isNotAuthorizedError(_ error: Error) -> Bool {
        if case .client(let clientError, _) = error as? SdkError<GetIdOutputError>,
           case .retryError(let serviceError) = clientError,
           let sdkError = serviceError as? SdkError<GetIdOutputError>,
           case .service(let getIdError, _ ) = sdkError,
           case .notAuthorizedException = getIdError {
            return true
        }
        return false
    }
}

extension FetchIdentityId: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension FetchIdentityId: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
