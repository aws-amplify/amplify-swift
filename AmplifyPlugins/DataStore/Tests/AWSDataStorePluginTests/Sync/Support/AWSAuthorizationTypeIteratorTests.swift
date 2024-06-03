//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore

class AWSAuthorizationTypeIteratorTests: XCTestCase {
    
    func testEmptyIterator_hasNextValue_false() throws {
        var iterator = AWSAuthorizationTypeIterator(withValues: [])
       
        XCTAssertFalse(iterator.hasNext)
        XCTAssertNil(iterator.next())
    }
    
    func testOneElementIterator_hasNextValue_once() throws {
        var iterator = AWSAuthorizationTypeIterator(withValues: [.designated(.amazonCognitoUserPools)])

        XCTAssertTrue(iterator.hasNext)
        XCTAssertNotNil(iterator.next())
        
        XCTAssertFalse(iterator.hasNext)
    }
    
    func testTwoElementsIterator_hasNextValue_twice() throws {
        var iterator = AWSAuthorizationTypeIterator(withValues: [
            .designated(.amazonCognitoUserPools),
            .designated(.apiKey)
        ])

        XCTAssertTrue(iterator.hasNext)
        XCTAssertNotNil(iterator.next())
        
        XCTAssertTrue(iterator.hasNext)
        XCTAssertNotNil(iterator.next())
        
        XCTAssertFalse(iterator.hasNext)
    }
}
