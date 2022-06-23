//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum SignInChallengeState: State {

    case notStarted

    case waitingForAnswer(RespondToAuthChallenge)

    case verifying(RespondToAuthChallenge, String)

    case verified

    case error(RespondToAuthChallenge, SignInError)
}

extension SignInChallengeState {

    var type: String {
        switch self {
        case .notStarted: return "SignInChallengeState.notStarted"
        case .waitingForAnswer: return "SignInChallengeState.waitingForAnswer"
        case .verifying: return "SignInChallengeState.verifying"
        case .verified: return "SignInChallengeState.verified"
        case .error: return "SignInChallengeState.error"
        }
    }
}

extension SignInChallengeState: Equatable {
    static func == (lhs: SignInChallengeState, rhs: SignInChallengeState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
            (.waitingForAnswer, .waitingForAnswer),
            (.verifying, .verifying),
            (.verified, .verified),
            (.error, .error):
            return true
        default: return false
        }
    }


}
