//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

// TOOD: Figure out how to move this to AmplifyTestCommon. Last time I tried, I wasn't able to `import XCTest` in the
// extension file, presumably because AmplifyTestCommon isn't a test target?
extension XCTestCase {
    /// Execute `block` inside a do/catch block, and fail the test with an XCTFail if the block throws an error
    func tryOrFail(block: () async throws -> Void) async {
        do {
            try await block()
        } catch {
            XCTFail(String(describing: error))
        }
    }
}
