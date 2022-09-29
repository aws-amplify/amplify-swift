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
        try await list.fetch()
        guard case .loaded = list.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        try await list.fetch()
    }

    func testFetchFailure() async throws {
        let mockListProvider = MockListProvider<BasicModel>(
            error: CoreError.listOperation("", "", nil)).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)

        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
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
    }

    func testHasNextPageSuccess() async throws {
        let nextPage = List(elements: [BasicModel]())
        let mockListProvider = MockListProvider<BasicModel>(nextPage: nextPage).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        try await list.fetch()
        guard case .loaded = list.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        XCTAssertTrue(list.hasNextPage())
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
        _ = try await list.getNextPage()
        
        guard case .loaded = list.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        _ = try await list.getNextPage()
    }

    func testGetNextPageFailure() async throws {
        let mockListProvider = MockListProvider<BasicModel>(
            errorOnNextPage: CoreError.clientValidation("", "", nil)).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        try await list.fetch()
        do {
            _ = try await list.getNextPage()
            XCTFail("Should have failed")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
