//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import libtommathAmplify
import s2nbignum

extension AmplifyBigInt {

    func sign() -> AmplifyBigIntSign {
        value.sign == AMPLIFY_MP_ZPOS ? .positive : .negative
    }
}

public enum AmplifyBigIntSign {
    case positive
    case negative
}
