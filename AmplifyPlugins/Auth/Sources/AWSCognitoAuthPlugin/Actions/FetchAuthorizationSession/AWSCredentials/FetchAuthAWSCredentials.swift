//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoIdentity
import ClientRuntime
import Foundation

struct FetchAuthAWSCredentials: Action {

    let identifier = "FetchAuthAwsCredentials"

    let loginsMap: [String: String]

    let identityID: String

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let authEnv = environment as? AuthEnvironment,
              let authZEnvironment = authEnv.authorizationEnvironment,
              let client = try? authZEnvironment.cognitoIdentityFactory()
        else {
            let authZError = FetchSessionError.noIdentityPool
            let event = FetchAuthSessionEvent(eventType: .throwError(authZError))
            await dispatcher.send(event)
            return
        }

        await fetchCredentials(
            withIdentityID: identityID,
            canRetryWithFreshIdentityID: true,
            client: client,
            authZEnvironment: authZEnvironment,
            dispatcher: dispatcher,
            environment: environment
        )
    }

    private func fetchCredentials(
        withIdentityID identityID: String,
        canRetryWithFreshIdentityID: Bool,
        client: CognitoIdentityBehavior,
        authZEnvironment: AuthorizationEnvironment,
        dispatcher: EventDispatcher,
        environment: Environment
    ) async {
        let getCredentialsInput = GetCredentialsForIdentityInput(
            identityId: identityID,
            logins: loginsMap
        )

        do {
            let response = try await client.getCredentialsForIdentity(input: getCredentialsInput)
            guard let identityId = response.identityId else {
                let event = FetchAuthSessionEvent(eventType: .throwError(.invalidIdentityID))
                await dispatcher.send(event)
                logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                return
            }
            guard let awsCredentials = response.credentials,
                  let accessKey = awsCredentials.accessKeyId,
                  let secretKey = awsCredentials.secretKey,
                  let sessionKey = awsCredentials.sessionToken,
                  let expiration = awsCredentials.expiration
            else {
                let event = FetchAuthSessionEvent(eventType: .throwError(.invalidAWSCredentials))
                await dispatcher.send(event)
                logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                return
            }
            let awsCognitoCredentials = AuthAWSCognitoCredentials(
                accessKeyId: accessKey,
                secretAccessKey: secretKey,
                sessionToken: sessionKey,
                expiration: expiration
            )
            let event = FetchAuthSessionEvent(
                eventType: .fetchedAWSCredentials(identityId, awsCognitoCredentials))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)

        } catch {
            // Rejected identity ID: evict and retry via fresh GetId.
            if canRetryWithFreshIdentityID, isStaleIdentityError(error) {
                await retryWithFreshIdentityID(
                    client: client,
                    authZEnvironment: authZEnvironment,
                    dispatcher: dispatcher,
                    environment: environment
                )
                return
            }
            let event = FetchAuthSessionEvent(eventType: .throwError(.service(error)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        }
    }

    private func retryWithFreshIdentityID(
        client: CognitoIdentityBehavior,
        authZEnvironment: AuthorizationEnvironment,
        dispatcher: EventDispatcher,
        environment: Environment
    ) async {
        let getIdInput = GetIdInput(
            identityPoolId: authZEnvironment.identityPoolConfiguration.poolId,
            logins: loginsMap
        )
        do {
            let response = try await client.getId(input: getIdInput)
            guard let freshIdentityID = response.identityId else {
                let event = FetchAuthSessionEvent(eventType: .throwError(.invalidIdentityID))
                await dispatcher.send(event)
                return
            }
            await fetchCredentials(
                withIdentityID: freshIdentityID,
                canRetryWithFreshIdentityID: false,
                client: client,
                authZEnvironment: authZEnvironment,
                dispatcher: dispatcher,
                environment: environment
            )
        } catch {
            let event = FetchAuthSessionEvent(eventType: .throwError(.service(error)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        }
    }

    // Codes returned when the identity ID is stale.
    private func isStaleIdentityError(_ error: Error) -> Bool {
        error is AWSCognitoIdentity.NotAuthorizedException ||
        error is AWSCognitoIdentity.ResourceNotFoundException
    }
}

extension FetchAuthAWSCredentials: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension FetchAuthAWSCredentials: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
