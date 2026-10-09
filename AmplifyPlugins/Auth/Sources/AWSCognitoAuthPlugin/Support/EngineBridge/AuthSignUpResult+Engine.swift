//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import InternalAWSCognitoAuth

// Conversions between `Amplify.AuthSignUpResult` / `AuthSignUpStep` / `AuthUserAttribute` and the
// engine's `EngineSignUpResult` / `EngineSignUpStep` / `EngineUserAttribute`. Case to case; the delivery
// details go through `AuthCodeDeliveryDetails+Engine.swift`.

extension AuthSignUpResult {

    init(_ result: EngineSignUpResult) {
        self.init(AuthSignUpStep(result.nextStep), userID: result.userID)
    }
}

extension EngineSignUpResult {

    init(_ result: AuthSignUpResult) {
        self.init(EngineSignUpStep(result.nextStep), userID: result.userID)
    }
}

extension AuthSignUpStep {

    init(_ step: EngineSignUpStep) {
        switch step {
        case .confirmUser(let details, let info, let userId):
            self = .confirmUser(details.map { AuthCodeDeliveryDetails($0) }, info, userId)
        case .completeAutoSignIn(let session):
            self = .completeAutoSignIn(session)
        case .done:
            self = .done
        }
    }
}

extension EngineSignUpStep {

    init(_ step: AuthSignUpStep) {
        switch step {
        case .confirmUser(let details, let info, let userId):
            self = .confirmUser(details.map { EngineCodeDeliveryDetails($0) }, info, userId)
        case .completeAutoSignIn(let session):
            self = .completeAutoSignIn(session)
        case .done:
            self = .done
        }
    }
}

extension EngineUserAttribute {

    /// The key becomes its Cognito name, as `InitiateSignUp` did before the fork (`key.rawValue`).
    init(_ attribute: AuthUserAttribute) {
        self.init(key: attribute.key.rawValue, value: attribute.value)
    }
}

extension AuthUserAttribute {

    init(_ attribute: EngineUserAttribute) {
        self.init(AuthUserAttributeKey(rawValue: attribute.key), value: attribute.value)
    }
}
