//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public typealias UserId = String
public typealias Session = String

/// SignUp step to be followed.
public enum AuthSignUpStep {

    /// Need to confirm the user
    case confirmUser(
        AuthCodeDeliveryDetails? = nil,
        AdditionalInfo? = nil,
        UserId? = nil
    )

    /// Sign Up successfully completed
    /// The customers can use this step to determine if they want to complete sign in
    case completeAutoSignIn(Session)

    /// Sign up is complete
    case done
}

extension AuthSignUpStep: Sendable { }

extension AuthSignUpStep: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    /// The default enum printing, with the auto sign-in session redacted: the step is logged as part of a sign-up
    /// result, and the session, with the username, signs the user in. Match `.completeAutoSignIn(let session)` for the
    /// value.
    public var description: String {
        switch self {
        case .confirmUser(let details, let additionalInfo, let userId):
            return "confirmUser(\(String(reflecting: details)), \(String(reflecting: additionalInfo)), "
                + "\(String(reflecting: userId)))"
        case .completeAutoSignIn:
            return "completeAutoSignIn(\(String(reflecting: Self.redactedSession)))"
        case .done:
            return "done"
        }
    }

    public var debugDescription: String {
        "\(String(reflecting: Self.self)).\(description)"
    }

    /// For `dump` and debuggers: the auto sign-in session redacted.
    public var customMirror: Mirror {
        switch self {
        case .confirmUser(let details, let additionalInfo, let userId):
            return Mirror(self, children: ["confirmUser": (details, additionalInfo, userId)], displayStyle: .enum)
        case .completeAutoSignIn:
            return Mirror(self, children: ["completeAutoSignIn": Self.redactedSession], displayStyle: .enum)
        case .done:
            return Mirror(self, children: [:], displayStyle: .enum)
        }
    }

    private static let redactedSession = "<REDACTED>"
}
