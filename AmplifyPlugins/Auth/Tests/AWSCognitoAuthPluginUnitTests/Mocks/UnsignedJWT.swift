//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum UnsignedJWT {

    /// An unsigned JWT with these payload claims, base64url-encoded without padding, as Cognito sends them.
    static func make(_ claims: [String: Any]) -> String {
        func base64URL(_ data: Data) -> String {
            data.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        let header = base64URL(Data(#"{"alg":"none","typ":"JWT"}"#.utf8))
        // swiftlint:disable:next force_try
        let payload = base64URL(try! JSONSerialization.data(withJSONObject: claims))
        return "\(header).\(payload).signature"
    }
}
