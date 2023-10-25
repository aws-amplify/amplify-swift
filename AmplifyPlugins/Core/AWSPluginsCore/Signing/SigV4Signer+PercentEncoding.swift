//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SigV4Signer {
    struct PercentEncoding {
        let allowedCharacters: CharacterSet
        func encode(_ string: String) -> String {
            string.addingPercentEncoding(
                withAllowedCharacters: allowedCharacters
            ) ?? string
        }

        static let query = PercentEncoding(
            allowedCharacters: CharacterSet(charactersIn:"/;+").inverted
        )

        static let uri = PercentEncoding(
            allowedCharacters: CharacterSet(
                charactersIn:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
            )
        )

        static let uriWithSlash = PercentEncoding(
            allowedCharacters: CharacterSet(
                charactersIn:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~/"
            )
        )
    }
}
