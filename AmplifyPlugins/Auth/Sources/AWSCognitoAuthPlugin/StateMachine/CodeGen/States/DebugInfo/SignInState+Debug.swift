//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignInState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {

        let additionalMetadataDictionary: [String: Any]

        switch self {

        case .signingInWithSRP(let srpSignInState, let signInEventData):
            additionalMetadataDictionary = srpSignInState.debugDictionary.merging(
                signInEventData.debugDictionary, uniquingKeysWith: {$1}
            )
        case .signingInWithHostedUI(let substate):
            additionalMetadataDictionary = substate.debugDictionary
        case .resolvingChallenge(let challengeState, let challengeType, let signInMethod):

            additionalMetadataDictionary = challengeState.debugDictionary.merging(
                [
                    "challengeType": challengeType,
                    "signInMethod": signInMethod
                ],
                uniquingKeysWith: {$1})

        case .notStarted:
            additionalMetadataDictionary = [:]
        case .signingInWithSRPCustom(let srpstate, _):
            additionalMetadataDictionary = ["SRPSignInStaet": srpstate.debugDictionary]
        case .signingInWithCustom(let customSignIn, _):
            additionalMetadataDictionary = ["CustomSignInState": customSignIn.debugDictionary]
        case .signingInViaMigrateAuth(let migrateSignInState, _):
            additionalMetadataDictionary = ["MigrateSignInState": migrateSignInState.debugDictionary]
        case .confirmingDevice:
            additionalMetadataDictionary = [:]
        case .resolvingDeviceSrpa(let deviceSRPState):
            additionalMetadataDictionary = ["DeviceSRPState": deviceSRPState.debugDictionary]
        case .signedIn(let data):
            additionalMetadataDictionary = ["SignedInData": data.debugDictionary]
        case .resolvingTOTPSetup(let signInTOTPSetupState, let signInEventData):
            additionalMetadataDictionary = [
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
