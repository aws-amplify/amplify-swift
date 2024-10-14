//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignInState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {

        let additionalMetadataDictionary: [String: Any] = switch self {

        case .signingInWithSRP(let srpSignInState, let signInEventData):
            srpSignInState.debugDictionary.merging(
                signInEventData.debugDictionary, uniquingKeysWith: {$1}
            )
        case .signingInWithHostedUI(let substate):
            substate.debugDictionary
        case .resolvingChallenge(let challengeState, let challengeType, let signInMethod):

            challengeState.debugDictionary.merging(
                [
                    "challengeType": challengeType,
                    "signInMethod": signInMethod
                ],
                uniquingKeysWith: {$1}
            )

        case .notStarted:
            [:]
        case .signingInWithSRPCustom(let srpstate, _):
            ["SRPSignInStaet": srpstate.debugDictionary]
        case .signingInWithCustom(let customSignIn, _):
            ["CustomSignInState": customSignIn.debugDictionary]
        case .signingInViaMigrateAuth(let migrateSignInState, _):
            ["MigrateSignInState": migrateSignInState.debugDictionary]
        case .confirmingDevice:
            [:]
        case .resolvingDeviceSrpa(let deviceSRPState):
            ["DeviceSRPState": deviceSRPState.debugDictionary]
        case .signedIn(let data):
            ["SignedInData": data.debugDictionary]
        case .resolvingTOTPSetup(let signInTOTPSetupState, let signInEventData):
            [
                "SignInTOTPSetupState": signInTOTPSetupState.debugDictionary,
                "SignInEventData": signInEventData.debugDictionary]
        case .autoSigningIn(let data):
            additionalMetadataDictionary = ["SignInData": data.debugDictionary]
        case .error:
            additionalMetadataDictionary = [:]
        case .signingInWithUserAuth(let signInEventData):
            additionalMetadataDictionary = ["signingInWithUserAuth": signInEventData.debugDictionary]
        case .signingInWithWebAuthn(let webAuthnState):
            additionalMetadataDictionary = [
                "signingInWithWebAuthn": webAuthnState.debugDictionary
            ]
        }
        return [type: additionalMetadataDictionary]
    }
}
