//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import hierarchical_state_machine_swift
import AWSCognitoIdentityProvider

// TODO: Validate if we still need this command.
struct VerifyPasswordReponse: Command {
    let identifier = "VerifyPasswordReponse"

    let stateData: SRPStateData
    let authResponse: RespondToAuthChallengeOutputResponse

    init(stateData: SRPStateData,
         authResponse: RespondToAuthChallengeOutputResponse)
    {
        self.stateData = stateData
        self.authResponse = authResponse
    }

    func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) {
        let timer = LoggingTimer(identifier).start("### Starting execution")
        guard let environment = environment as? SRPAuthEnvironment else {
            fatalError("TODO: Replace this with a dispatcher.send()")
        }
        if let authenticationResult = authResponse.authenticationResult {
//            let idToken = authenticationResult.idToken
//            let accessToken = authenticationResult.accessToken
//            let refeshToken = authenticationResult.refreshToken
//            let expiresIn = authenticationResult.expiresIn
//            let tokenType = authenticationResult.tokenType
//            let latestDeviceMetadata = authenticationResult.latestDeviceMetadata
            let signedInData = SignedInData(
                userId: "",
                userName: stateData.username,
                signedInDate: Date(),
                signInMethod: .srp
            )
            let event = SRPSignInEvent(
                id: environment.eventIDFactory(),
                eventType: .finalizeSRPSignIn(signedInData),
                time: Date()
            )
            timer.stop("### sending SRPSignInEvent.done")
            dispatcher.send(event)
        }

//        let nextChallenge = authResponse.challengeName
//        let session = authResponse.session

    }
}

extension VerifyPasswordReponse: DefaultLogger { }

extension VerifyPasswordReponse: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "stateData": stateData.debugDictionary,
            "authResponse": authResponse
        ]
    }
}

extension VerifyPasswordReponse: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
