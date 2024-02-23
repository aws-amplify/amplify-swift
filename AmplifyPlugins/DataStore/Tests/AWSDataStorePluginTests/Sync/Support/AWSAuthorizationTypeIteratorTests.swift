//
//  AWSAuthorizationTypeIteratorTests.swift
//  
//
//  Created by Tomasz Trela on 10/02/2024.
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
        var iterator = AWSAuthorizationTypeIterator(withValues: [.amazonCognitoUserPools])
        
        XCTAssertTrue(iterator.hasNext)
        XCTAssertNotNil(iterator.next())
        
        XCTAssertFalse(iterator.hasNext)
    }
    
    func testTwoElementsIterator_hasNextValue_twice() throws {
        var iterator = AWSAuthorizationTypeIterator(withValues: [.amazonCognitoUserPools, .apiKey])
        
        XCTAssertTrue(iterator.hasNext)
        XCTAssertNotNil(iterator.next())
        
        XCTAssertTrue(iterator.hasNext)
        XCTAssertNotNil(iterator.next())
        
        XCTAssertFalse(iterator.hasNext)
    }
}
