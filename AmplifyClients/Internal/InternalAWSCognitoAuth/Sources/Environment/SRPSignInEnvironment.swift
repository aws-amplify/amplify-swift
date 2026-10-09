//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

package protocol SRPSignInEnvironment: Environment {
    var srpAuthEnvironment: SRPAuthEnvironment { get }
}

package struct BasicSRPSignInEnvironment: SRPSignInEnvironment {

    package let srpAuthEnvironment: SRPAuthEnvironment

    package init(
        srpAuthEnvironment: SRPAuthEnvironment
    ) {
        self.srpAuthEnvironment = srpAuthEnvironment
    }
}
