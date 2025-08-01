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
        UserId? = nil)

    /// Sign Up successfully completed  
    /// The customers can use this step to determine if they want to complete sign in
    case completeAutoSignIn(Session)
    
    /// Sign up is complete
    case done
}

extension AuthSignUpStep: Sendable { }
