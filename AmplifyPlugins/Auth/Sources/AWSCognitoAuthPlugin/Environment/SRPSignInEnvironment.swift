//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import hierarchical_state_machine_swift


protocol SRPSignInEnvironment: Environment {
    var srpAuthEnvironment: SRPAuthEnvironment { get }
}

struct BasicSRPSignInEnvironment: SRPSignInEnvironment {

    let srpAuthEnvironment: SRPAuthEnvironment
}
