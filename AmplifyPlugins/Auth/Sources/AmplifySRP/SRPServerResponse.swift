//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AmplifyBigInteger

struct SRPServerResponse {
    let publicKey: BigInt
    let salt: BigInt
}
