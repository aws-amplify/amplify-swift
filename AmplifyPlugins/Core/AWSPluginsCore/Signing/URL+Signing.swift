//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension URL {
    var hostWithPort: String {
        let value: String

        switch (host, port) {
        case (.some(let host), .some(let port)):
            value = "\(host):\(String(port))"

        case (.some(let host), .none):
            value = host

        case (.none, .some):
            preconditionFailure("port shouldn't exist without host")

        case (.none, .none):
            value = ""
        }

        return value
    }

    func replacing(queryString: String) -> URL {
        let absolute = absoluteString.suffix(1) == "?"
        ? String(absoluteString.dropLast(1))
        : absoluteString

        let split = absolute.split(separator: "?")
        let url: URL?
        if split.count == 2 {
            let baseURL = String(split[0])
            url = URL(
                string: baseURL + "?" + queryString
            )
        } else {
            url = URL(string: absolute + "?" + queryString)
        }

        return url ?? self
    }
}
