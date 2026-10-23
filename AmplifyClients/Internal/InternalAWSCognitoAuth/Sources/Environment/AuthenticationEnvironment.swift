//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

package protocol AuthenticationEnvironment: Environment {

    var srpSignInEnvironment: SRPSignInEnvironment { get }
    var userPoolEnvironment: UserPoolEnvironment { get }

    var hostedUIEnvironment: HostedUIEnvironment? { get }
}

package struct BasicAuthenticationEnvironment: AuthenticationEnvironment {

    package let srpSignInEnvironment: SRPSignInEnvironment

    package let userPoolEnvironment: UserPoolEnvironment

    package let hostedUIEnvironment: HostedUIEnvironment?

    package init(
        srpSignInEnvironment: SRPSignInEnvironment,
        userPoolEnvironment: UserPoolEnvironment,
        hostedUIEnvironment: HostedUIEnvironment?
    ) {
        self.srpSignInEnvironment = srpSignInEnvironment
        self.userPoolEnvironment = userPoolEnvironment
        self.hostedUIEnvironment = hostedUIEnvironment
    }
}
