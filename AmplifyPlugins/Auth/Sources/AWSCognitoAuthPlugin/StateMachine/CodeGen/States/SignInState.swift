//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum SignInState: State {
    case notStarted
    case signingInWithSRP(SRPSignInState, SignInEventData)
    case signingInWithSRPCustom(SRPSignInState, SignInEventData)
    case signingInWithCustom(CustomSignInState, SignInEventData)
    case signingInViaMigrateAuth(MigrateSignInState, SignInEventData)
    case signingInWithUserAuth(SignInEventData)
    case signingInWithWebAuthn(WebAuthnSignInState)
    case resolvingChallenge(SignInChallengeState, AuthChallengeType, SignInMethod)
    case resolvingTOTPSetup(SignInTOTPSetupState, SignInEventData)
    case signingInWithHostedUI(HostedUISignInState)
    case autoSigningIn(SignInEventData)
    case confirmingDevice
    case resolvingDeviceSrpa(DeviceSRPState)
    case signedIn(SignedInData)
    case error
}

extension SignInState {

    var type: String {
        switch self {
        case .notStarted: return "SignInState.notStarted"
        case .signingInWithSRP: return "SignInState.signingInWithSRP"
        case .signingInWithHostedUI: return "SignInState.signingInWithHostedUI"
        case .signingInWithSRPCustom: return "SignInState.signingInWithSRPCustom"
        case .signingInWithCustom: return "SignInState.signingInWithCustom"
        case .signingInViaMigrateAuth: return "SignInState.signingInViaMigrateAuth"
        case .signingInWithUserAuth: return "SignInState.signingInWithUserAuth"
        case .autoSigningIn: return "SignInState.autoSigningIn"
        case .resolvingChallenge: return "SignInState.resolvingChallenge"
        case .resolvingTOTPSetup: return "SignInState.resolvingTOTPSetup"
        case .confirmingDevice: return "SignInState.confirmingDevice"
        case .resolvingDeviceSrpa: return "SignInState.resolvingDeviceSrpa"
        case .signedIn: return "SignInState.signedIn"
        case .error: return "SignInState.error"
        case .signingInWithWebAuthn: return "SignInState.signingInWithWebAuthn"
        }
    }
}
