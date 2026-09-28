//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct RandomStringGenerator: RandomStringBehavior {

    package init() {}

    package func generateUUID() -> String {
        return UUID().uuidString.lowercased()
    }

    package func generateRandom(byteSize: Int = 32) -> String? {
        var randomBytes = [UInt8](repeating: 0, count: byteSize)
        let result = SecRandomCopyBytes(kSecRandomDefault, byteSize, &randomBytes)
        guard result == errSecSuccess else {
            return nil
        }
        return HostedUIRequestHelper.urlSafeBase64(Data(randomBytes).base64EncodedString())
    }
}
