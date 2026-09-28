//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct SRPKeys {
    package let publicKeyHexValue: String
    package let privateKeyHexValue: String
}

extension SRPKeys: Codable { }
