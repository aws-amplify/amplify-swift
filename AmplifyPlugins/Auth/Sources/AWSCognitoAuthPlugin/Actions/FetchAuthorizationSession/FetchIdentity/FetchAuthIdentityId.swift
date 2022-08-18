//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import Foundation
import ClientRuntime

struct FetchAuthIdentityId: Action {

    let identifier = "FetchAuthIdentityId"

    let loginsMap: [String: String]

    init(loginsMap: [String: String] = [:]) {
        self.loginsMap = loginsMap
    }

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let authEnv = environment as? AuthEnvironment,
              let authZEnvironment = authEnv.authorizationEnvironment,
              let client = try? authZEnvironment.cognitoIdentityFactory()
        else {
            let authZError = AuthorizationError.configuration(
                message: AuthPluginErrorConstants.signedInIdentityIdWithNoCIDPError.errorDescription)
            let event = AuthorizationEvent(eventType: .throwError(authZError))
            await dispatcher.send(event)
            return
        }

        let getIdInput = GetIdInput(
            identityPoolId: authZEnvironment.identityPoolConfiguration.poolId,
            logins: loginsMap)

        do {
            let response = try await client.getId(input: getIdInput)

            guard let identityId = response.identityId else {
                let event = FetchAuthSessionEvent(eventType: .throwError(.invalidIdentityID))
                await dispatcher.send(event)
                return
            }
            let event = FetchAuthSessionEvent(eventType: .fetchedIdentityID(identityId))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        } catch {

            let event: FetchAuthSessionEvent
            if isNotAuthorizedError(error) {
                event = FetchAuthSessionEvent(eventType: .throwError(.notAuthorized))
            } else {
                event = FetchAuthSessionEvent(eventType: .throwError(.service(error)))
            }
            logVerbose("\(#fileID) Sending event \(event.type)",
                       environment: environment)
            await dispatcher.send(event)
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

extension FetchAuthIdentityId: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension FetchAuthIdentityId: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
