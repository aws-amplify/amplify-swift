//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

// Alphanumerics plus certain special characters defined in SEP
private let tokenNoHashCharacterSet = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!$%'*+-.^_`|~")
private let tokenCharacterSet = tokenNoHashCharacterSet.union(Set("#"))
private let substituteCharacter = Character("-")

extension String {

    var userAgentToken: String {
        String(map { tokenCharacterSet.contains($0) ? $0 : substituteCharacter })
    }

    var userAgentTokenNoHash: String {
        String(map { tokenNoHashCharacterSet.contains($0) ? $0 : substituteCharacter })
    }
}
