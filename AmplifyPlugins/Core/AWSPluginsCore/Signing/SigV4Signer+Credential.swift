//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SigV4Signer {
    struct Credential {
        let accessKey: String
        let secretKey: String
        let sessionToken: String?
    }
}
