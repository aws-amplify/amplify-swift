//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import libtommath

extension AmplifyBigInt {
    
    func sign() -> AmplifyBigIntSign {
        value.sign == MP_ZPOS ? .positive : .negative
    }
}

public enum AmplifyBigIntSign {
    case positive
    case negative
}
