//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The engine's copy of `Amplify.AuthSignUpResult`, with the same members and initializer.
///
/// Like the public type it is not `Equatable`. The plugin maps it to `AuthSignUpResult` in
/// `AWSCognitoAuthPlugin/Support/EngineBridge/AuthSignUpResult+Engine.swift`.
package struct EngineSignUpResult {

    /// Indicate whether the signUp flow is completed.
    package var isSignUpComplete: Bool {
        switch nextStep {
        case .completeAutoSignIn, .done:
            return true
        default:
            return false
        }
    }

    /// Shows the next step required to complete the signUp flow.
    package let nextStep: EngineSignUpStep

    /// User ID of the signed up user.
    package let userID: String?

    package init(
        _ nextStep: EngineSignUpStep,
        userID: String? = nil
    ) {
        self.nextStep = nextStep
        self.userID = userID
    }
}

extension EngineSignUpResult: Sendable { }

/// The engine's copy of `Amplify.AuthSignUpStep`: the same cases, in the same order, with the same
/// defaulted payloads. `AdditionalInfo` is `[String: String]` and `UserId` / `Session` are `String`, as
/// Amplify's typealiases are.
package enum EngineSignUpStep {

    /// Need to confirm the user
    case confirmUser(
        EngineCodeDeliveryDetails? = nil,
        [String: String]? = nil,
        String? = nil
    )

    /// Sign Up successfully completed
    /// The customers can use this step to determine if they want to complete sign in
    case completeAutoSignIn(String)

    /// Sign up is complete
    case done
}

extension EngineSignUpStep: Sendable { }

/// A user attribute on its way to Cognito: the wire name and the value.
///
/// The engine's copy of `Amplify.AuthUserAttribute`, with the key as the Cognito name
/// (`AuthUserAttributeKey.rawValue`), because `AuthUserAttributeKey` stays plugin-side.
/// The members keep the public names.
package struct EngineUserAttribute {

    /// The Cognito attribute name, for example `"email"` or `"custom:x"`.
    package let key: String

    package let value: String

    package init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

extension EngineUserAttribute: Equatable { }

extension EngineUserAttribute: Sendable { }
