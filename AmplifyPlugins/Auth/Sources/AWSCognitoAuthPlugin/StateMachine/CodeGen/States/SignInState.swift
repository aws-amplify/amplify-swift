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
    case resolvingChallenge(SignInChallengeState, AuthChallengeType)
    case signingInWithHostedUI(HostedUISignInState)
    case done
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
        case .resolvingChallenge: return "SignInState.resolvingChallenge"
        case .done: return "SignInState.done"
        case .error: return "SignInState.error"
        }
    }
}
