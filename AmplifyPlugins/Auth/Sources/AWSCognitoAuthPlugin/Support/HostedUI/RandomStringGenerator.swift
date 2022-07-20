//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct RandomStringGenerator: RandomStringBehavior {

    func generateUUID() -> String {
        return UUID().uuidString.lowercased()
    }

    func generateRandom(byteSize: Int = 32) -> String? {
        var randomBytes = [UInt8](repeating: 0, count: byteSize)
        let result = SecRandomCopyBytes(kSecRandomDefault, byteSize, &randomBytes)
        guard result == errSecSuccess else {
            return nil
        }
        return HostedUIRequestHelper.urlSafeBase64(Data(randomBytes).base64EncodedString())
    }
}
