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
    case signingInWithSocial
    case signingInWithCustom
    case resolvingSMSChallenge(SignInChallengeState)
    case done
    case error
}

extension SignInState {

    var type: String {
        switch self {
        case .notStarted: return "SignInState.notStarted"
        case .signingInWithSRP: return "SignInState.signingInWithSRP"
        case .signingInWithSocial: return "SignInState.signingInWithSocial"
        case .signingInWithCustom: return "SignInState.signingInWithCustom"
        case .resolvingSMSChallenge: return "SignInState.resolvingSMSChallenge"
        case .done: return "SignInState.done"
        case .error: return "SignInState.error"
        }
    }
}
