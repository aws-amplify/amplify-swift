//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension URLSessionTask {
    var eTag: String? {
        guard let response = response as? HTTPURLResponse else {
            return nil
        }

        let eTag = response.allHeaderFields["ETAG"] as? String
        return eTag
    }
}
