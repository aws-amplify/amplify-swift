//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SigV4Signer {
    struct HTTPMethod {
        let verb: String

        static let get = Self(verb: "GET")
    }
}
