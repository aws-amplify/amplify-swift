//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CryptoKit

extension SigV4Signer {
    static let hashedEmptyBody = SHA256.hash(data: [UInt8]()).hexDigest()
}
