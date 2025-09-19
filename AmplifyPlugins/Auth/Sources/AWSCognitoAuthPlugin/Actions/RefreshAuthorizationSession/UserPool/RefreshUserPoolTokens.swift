//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoIdentityProvider
import AWSPluginsCore
import ClientRuntime
import Foundation

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

            let config = environment.userPoolConfiguration
            let client = try? environment.cognitoUserPoolFactory()
            let existingTokens = existingSignedIndata.cognitoUserPoolTokens

            let deviceMetadata = await DeviceMetadataHelper.getDeviceMetadata(
                for: existingSignedIndata.username,
                with: environment
            )

            let deviceKey: String? = {
                if case .metadata(let data) = deviceMetadata {
                    return data.deviceKey
                }
                return nil
            }()

            let input = GetTokensFromRefreshTokenInput(
                clientId: config.clientId,
                clientMetadata: [:],
                clientSecret: config.clientSecret,
                deviceKey: deviceKey,
                refreshToken: existingTokens.refreshToken
            )

            logVerbose(
                "\(#fileID) Starting get tokens from refresh token", environment: environment
            )

            let response = try await client?.getTokensFromRefreshToken(input: input)

            logVerbose(
                "\(#fileID) Get tokens from refresh token response received",
                environment: environment
            )

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
                refreshToken: authenticationResult.refreshToken ?? existingTokens.refreshToken
            )

            let signedInData = SignedInData(
                signedInDate: existingSignedIndata.signedInDate,
                signInMethod: existingSignedIndata.signInMethod,
                cognitoUserPoolTokens: userPoolTokens
            )
            let event: RefreshSessionEvent

            if ((environment as? AuthEnvironment)?.identityPoolConfigData) != nil {
                let provider = CognitoUserPoolLoginsMap(
                    idToken: idToken,
                    region: config.region,
                    poolId: config.poolId
                )
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

        logVerbose("\(#fileID) Get tokens from refresh token complete", environment: environment)
    }
}

extension RefreshUserPoolTokens: DefaultLogger {
    static var log: Logger {
        Amplify.Logging.logger(
            forCategory: CategoryType.auth.displayName, forNamespace: String(describing: self)
        )
    }

    var log: Logger {
        Self.log
    }
}

extension RefreshUserPoolTokens: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "existingSignedInData": existingSignedIndata,
        ]
    }
}

extension RefreshUserPoolTokens: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
