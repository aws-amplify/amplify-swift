//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import AWSCognitoIdentityProvider
import Foundation
import ClientRuntime

struct RefreshUserPoolTokens: Action {

    let identifier = "RefreshUserPoolTokens"

    let existingSignedIndata: SignedInData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        do {

            logVerbose("\(#fileID) Starting execution", environment: environment)
            guard let environment = environment as? UserPoolEnvironment else {
                let event = RefreshSessionEvent.init(eventType: .throwError(.noUserPool))
                await dispatcher.send(event)
                return
            }

            let authEnv = try environment.authEnvironment()
            let config = environment.userPoolConfiguration
            let client = try? environment.cognitoUserPoolFactory()
            let existingTokens = existingSignedIndata.cognitoUserPoolTokens

            let deviceMetadata = await DeviceMetadataHelper.getDeviceMetadata(
                for: environment,
                with: existingSignedIndata.userName)

            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: existingSignedIndata.userName,
                credentialStoreClient: authEnv.credentialStoreClientFactory())

            let input = InitiateAuthInput.refreshAuthInput(
                username: existingSignedIndata.userName,
                refreshToken: existingTokens.refreshToken,
                clientMetadata: [:],
                asfDeviceId: asfDeviceId,
                deviceMetadata: deviceMetadata,
                environment: environment)

            logVerbose("\(#fileID) Starting initiate auth refresh token", environment: environment)

            let response = try await client?.initiateAuth(input: input)

            logVerbose("\(#fileID) Initiate auth response received", environment: environment)

            guard let authenticationResult = response?.authenticationResult,
                  let idToken = authenticationResult.idToken,
                  let accessToken = authenticationResult.accessToken
            else {

                let event = RefreshSessionEvent(eventType: .throwError(.invalidTokens))
                await dispatcher.send(event)
                logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                return
            }

            let userPoolTokens = AWSCognitoUserPoolTokens(
                idToken: idToken,
                accessToken: accessToken,
                refreshToken: existingTokens.refreshToken,
                expiresIn: authenticationResult.expiresIn
            )
            let signedInData = SignedInData(
                signedInDate: existingSignedIndata.signedInDate,
                signInMethod: existingSignedIndata.signInMethod,
                cognitoUserPoolTokens: userPoolTokens)
            let event: RefreshSessionEvent

            if ((environment as? AuthEnvironment)?.identityPoolConfigData) != nil {
                let provider = CognitoUserPoolLoginsMap(
                    idToken: idToken,
                    region: config.region,
                    poolId: config.poolId)
                event = .init(eventType: .refreshIdentityInfo(signedInData, provider))
            } else {
                event = .init(eventType: .refreshedCognitoUserPool(signedInData))
            }
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)

        } catch {
            let event = RefreshSessionEvent(eventType: .throwError(.service(error)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        }

        logVerbose("\(#fileID) Initiate auth complete", environment: environment)
    }
}

extension RefreshUserPoolTokens: DefaultLogger { }

extension RefreshUserPoolTokens: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "existingSignedInData": existingSignedIndata
        ]
    }
}

extension RefreshUserPoolTokens: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
