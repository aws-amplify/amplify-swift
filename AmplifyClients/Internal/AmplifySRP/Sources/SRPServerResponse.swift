//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyBigInteger
import Foundation

struct SRPServerResponse {
    let publicKey: BigInt
    let salt: BigInt
}
