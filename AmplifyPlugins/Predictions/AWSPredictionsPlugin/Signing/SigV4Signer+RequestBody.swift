//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CryptoKit

extension SigV4Signer {
    struct RequestBody {
        let input: Data
        let hash: (Data) -> String

        static func string(_ string: String) -> RequestBody {
            .init(
                input: Data(string.utf8),
                hash: { data in
                    SHA256.hash(data: data).hexDigest()
                }
            )
        }

        static func data(_ data: Data) -> RequestBody {
            .init(
                input: data,
                hash: { data in
                    SHA256.hash(data: data).hexDigest()
                }
            )
        }
    }
}
