//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class TreeTests: XCTestCase, @unchecked Sendable {

    func testTreeWithChildren() {
        let tree = Tree<Int>(value: 0)
        let child1 = Tree<Int>(value: 1)
        let child2 = Tree<Int>(value: 2)

        tree.addChild(settingParentOf: child1)
        tree.addChild(settingParentOf: child2)

        XCTAssertNotNil(tree)
        XCTAssertEqual(tree.value, 0)
        XCTAssertEqual(tree.children.count, 2)
        XCTAssertNotNil(child1.parent)
        XCTAssertEqual(child1.parent?.value, tree.value)
        XCTAssertNotNil(child2.parent)
        XCTAssertEqual(child2.parent?.value, tree.value)
    }
}
