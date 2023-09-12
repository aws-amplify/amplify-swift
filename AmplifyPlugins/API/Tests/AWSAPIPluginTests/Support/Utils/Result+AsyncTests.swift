//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
@testable import AWSAPIPlugin

class ResultAsyncTests: XCTestCase {

    func testFlatMapAsync_withSuccess_applyFunction() async {
        func plus1(_ number: Int) async -> Int {
            return number + 1
        }

        let result = Result<Int, Error>.success(0)
        let plus1Result = await result.flatMapAsync {
            .success(await plus1($0))
        }

        switch plus1Result {
        case .success(let plus1Result):
            XCTAssertEqual(plus1Result, 1)
        case .failure(let error):
            XCTFail("Failed with error \(error)")
        }
    }

    func testFlatMapAsync_withFailure_notApplyFunction() async {
        func arrayCount(_ array: [Int]) async -> Int {
            return array.count
        }


        let expectedError = TestError()
        let result = Result<[Int], Error>.failure(expectedError)
        let count = await result.flatMapAsync {
            .success(await arrayCount($0))
        }

        switch count {
        case .success:
            XCTFail("Should fail")
        case .failure(let error):
            XCTAssertTrue(error is TestError)
            XCTAssertEqual(ObjectIdentifier(expectedError), ObjectIdentifier(error as! TestError))
        }
    }
}

fileprivate class TestError: Error { }
