//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import Amplify
@testable import AWSCognitoAuthPlugin

struct MockRandomStringGenerator: RandomStringBehavior {

    let mockString: String?

    let mockUUID: String

    func generateRandom(byteSize: Int) -> String? {
        return mockString
    }

    func generateUUID() -> String {
        return mockUUID
    }
}
