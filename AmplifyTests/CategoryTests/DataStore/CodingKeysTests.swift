//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AmplifyTestCommon

class CodingKeysTests: XCTestCase {

    func testSchemaHasCorrectColumnName() throws {
        ModelRegistry.register(modelType: Comment.self)
        let commentQPO: QueryPredicateOperation = Comment.keys.id == "1234"
        XCTAssertEqual(commentQPO.field, "id")
    }

    func testSchemaWithBelongsToHasCorrectColumnName() throws {
        ModelRegistry.register(modelType: Comment.self)
        let commentQPO: QueryPredicateOperation = Comment.keys.post == "5678"
        XCTAssertEqual(commentQPO.field, "commentPostId")
    }

}
