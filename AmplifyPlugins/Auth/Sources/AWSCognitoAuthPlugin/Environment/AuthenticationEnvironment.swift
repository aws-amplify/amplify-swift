//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//



protocol AuthenticationEnvironment: Environment {

    var srpSignInEnvironment: SRPSignInEnvironment { get }
    var userPoolEnvironment: UserPoolEnvironment { get }
}

public struct BasicAuthenticationEnvironment: AuthenticationEnvironment {
    let srpSignInEnvironment: SRPSignInEnvironment
    let userPoolEnvironment: UserPoolEnvironment
}
