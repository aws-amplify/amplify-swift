//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct VerifyPasswordSRP: Action {
    let identifier = "VerifyPasswordSRP"

    let stateData: SRPStateData
    let authResponse: InitiateAuthOutputResponse

    init(stateData: SRPStateData,
         authResponse: InitiateAuthOutputResponse) {
        self.stateData = stateData
        self.authResponse = authResponse
    }

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        let inputUsername = stateData.username
        var username = inputUsername
        var deviceMetadata = DeviceMetadata.noData
        do {
            let srpEnv = try environment.srpEnvironment()
            let userPoolEnv = try environment.userPoolEnvironment()
            let srpClient = try SRPSignInHelper.srpClient(srpEnv)
            let parameters = try challengeParameters()

            username = parameters["USERNAME"] ?? inputUsername
            let userIdForSRP = parameters["USER_ID_FOR_SRP"] ?? inputUsername

            let saltHex = try saltHex(parameters)
            let secretBlockString = try secretBlockString(parameters)
            let secretBlock = try secretBlock(secretBlockString)
            let serverPublicB = try serverPublic(parameters)

            deviceMetadata = await DeviceMetadataHelper.getDeviceMetadata(
                for: username,
                with: environment)
            let signature = try signature(userIdForSRP: userIdForSRP,
                                          saltHex: saltHex,
                                          secretBlock: secretBlock,
                                          serverPublicBHexString: serverPublicB,
                                          srpClient: srpClient,
                                          poolId: userPoolEnv.userPoolConfiguration.poolId)
            let request = RespondToAuthChallengeInput.passwordVerifier(
                username: username,
                stateData: stateData,
                session: authResponse.session,
                secretBlock: secretBlockString,
                signature: signature,
                deviceMetadata: deviceMetadata,
                environment: userPoolEnv)
            let responseEvent = try await UserPoolSignInHelper.sendRespondToAuth(
                request: request,
                for: username,
                signInMethod: .apiBased(.userSRP),
                environment: userPoolEnv)
            logVerbose("\(#fileID) Sending event \(responseEvent)",
                       environment: environment)
            await dispatcher.send(responseEvent)
        } catch let error as SignInError {
            logVerbose("\(#fileID) SRPSignInError \(error)", environment: environment)
            let event = SignInEvent(
                eventType: .throwPasswordVerifierError(error)
            )
            await dispatcher.send(event)
        } catch {
            logVerbose("\(#fileID) SRPSignInError Generic \(error)", environment: environment)
            let authError = SignInError.service(error: error)
            let event = SignInEvent(
                eventType: .throwAuthError(authError)
            )
            await dispatcher.send(event)
        }
    }
}

extension VerifyPasswordSRP: DefaultLogger { }

extension VerifyPasswordSRP: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "stateData": stateData.debugDictionary,
            "authResponse": authResponse
        ]
    }
}

extension VerifyPasswordSRP: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
