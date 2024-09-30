//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSSDKSwiftCLI
import XCTest

class LazyValueTests: XCTestCase {
    
    func testLazyValue() {
        var count: Int = 0
        let subject = LazyValue<Int> {
            count += 1
            return 1
        }
        XCTAssertEqual(count, 0)
        
        let value = subject.value
        XCTAssertEqual(value, 1)
        XCTAssertEqual(count, 1)
        
        let value2 = subject.value
        XCTAssertEqual(value2, 1)
        XCTAssertEqual(count, 1)
    }
}
