//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension URLSessionTask {
    var eTag: String? {
        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }

        let keys = httpResponse.allHeaderFields.keys
            .compactMap({ $0 as? String })
            .filter({ $0.uppercased() == "ETAG" })

        guard let key = keys.first,
              let eTag = httpResponse.allHeaderFields[key] as? String else {
                  return nil
              }

        return eTag
    }
}
