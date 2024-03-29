//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

extension ListTests {
    
    func testFetchSuccess() async throws {
        let mockListProvider = MockListProvider<BasicModel>(elements: [BasicModel]()).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let fetchComplete = expectation(description: "fetch completed")
        Task {
            
            try await list.fetch()
            guard case .loaded = list.loadedState else {
                XCTFail("Should be loaded")
                return
            }
            fetchComplete.fulfill()
        }
        await fulfillment(of: [fetchComplete], timeout: 1)
        
        let fetchComplete2 = expectation(description: "fetch completed")
        Task {
            try await list.fetch()
            fetchComplete2.fulfill()
        }
        await fulfillment(of: [fetchComplete2], timeout: 1)
    }

    func testFetchFailure() async throws {
        let mockListProvider = MockListProvider<BasicModel>(
            error: CoreError.listOperation("", "", nil)).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)

        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let fetchCompleted = expectation(description: "fetch completed")
        Task {
            do {
                try await list.fetch()
                XCTFail("Should have failed")
            } catch {
                XCTAssertNotNil(error)
            }
            guard case .notLoaded = list.loadedState else {
                XCTFail("Should not be loaded")
                return
            }
            fetchCompleted.fulfill()
        }
        
        await fulfillment(of: [fetchCompleted], timeout: 1.0)
    }

    func testHasNextPageSuccess() async throws {
        let nextPage = List(elements: [BasicModel]())
        let mockListProvider = MockListProvider<BasicModel>(nextPage: nextPage).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let fetchCompleted = expectation(description: "fetch completed")
        Task {
            try await list.fetch()
            guard case .loaded = list.loadedState else {
                XCTFail("Should be loaded")
                return
            }
            XCTAssertTrue(list.hasNextPage())
            fetchCompleted.fulfill()
        }
        await fulfillment(of: [fetchCompleted], timeout: 1.0)
    }

    func testGetNextPageSuccess() async throws {
        let nextPage = List(elements: [BasicModel]())
        let mockListProvider = MockListProvider<BasicModel>(nextPage: nextPage).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        try await list.fetch()
        let getNextPageSuccess = expectation(description: "getNextPage successful")
        Task {
            _ = try await list.getNextPage()
            getNextPageSuccess.fulfill()
        }
        await fulfillment(of: [getNextPageSuccess], timeout: 1.0)
        
        guard case .loaded = list.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        let getNextPageSuccess2 = expectation(description: "getNextPage successful")
        Task {
            _ = try await list.getNextPage()
            getNextPageSuccess2.fulfill()
        }
        await fulfillment(of: [getNextPageSuccess2], timeout: 1.0)

    }

    func testGetNextPageFailure() async throws {
        let mockListProvider = MockListProvider<BasicModel>(
            errorOnNextPage: CoreError.clientValidation("", "", nil)).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let fetchCompleted = expectation(description: "fetch completed")
        Task {
            try await list.fetch()
            fetchCompleted.fulfill()
        }
        await fulfillment(of: [fetchCompleted], timeout: 1.0)
        
        let getNextPageSuccess = expectation(description: "getNextPage successful")
        Task {
            do {
                _ = try await list.getNextPage()
                XCTFail("Should have failed")
            } catch {
                XCTAssertNotNil(error)
            }
            getNextPageSuccess.fulfill()
        }
        await fulfillment(of: [getNextPageSuccess], timeout: 1.0)
    }
}
