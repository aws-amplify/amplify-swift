//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

extension ListTests {
    
    func testFetchSuccess() {
        let mockListProvider = MockListProvider<BasicModel>(elements: [BasicModel]()).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        let fetchComplete = expectation(description: "fetch completed")
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        list.fetch { result in
            switch result {
            case .success:
                fetchComplete.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [fetchComplete], timeout: 1)
        guard case .loaded = list.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        let loadedListfetchComplete = expectation(description: "fetch completed on a loaded list")
        list.fetch { result in
            switch result {
            case .success:
                loadedListfetchComplete.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [loadedListfetchComplete], timeout: 1)
    }

    func testFetchFailure() {
        let mockListProvider = MockListProvider<BasicModel>(
            error: CoreError.listOperation("", "", nil)).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        let fetchFailed = expectation(description: "fetch failed")
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        list.fetch { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure:
                fetchFailed.fulfill()
            }
        }
        wait(for: [fetchFailed], timeout: 1)
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
    }

    func testHasNextPageSuccess() {
        let nextPage = List(elements: [BasicModel]())
        let mockListProvider = MockListProvider<BasicModel>(nextPage: nextPage).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let fetchCompleted = expectation(description: "Fetch completed")
        list.fetch { result in
            switch result {
            case .success:
                fetchCompleted.fulfill()
            case .failure(let error):
                XCTFail("Failed with error \(error)")
            }
        }
        wait(for: [fetchCompleted], timeout: 1)
        guard case .loaded = list.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        XCTAssertTrue(list.hasNextPage())
    }

    func testGetNextPageSuccess() {
        let nextPage = List(elements: [BasicModel]())
        let mockListProvider = MockListProvider<BasicModel>(nextPage: nextPage).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let fetchCompleted = expectation(description: "Fetch completed")
        list.fetch { result in
            switch result {
            case .success:
                fetchCompleted.fulfill()
            case .failure(let error):
                XCTFail("Failed with error \(error)")
            }
        }
        wait(for: [fetchCompleted], timeout: 1)
        let getNextPageComplete = expectation(description: "get next page completed")
        list.getNextPage { result in
            switch result {
            case .success:
                getNextPageComplete.fulfill()
            case .failure(let coreError):
                XCTFail("\(coreError)")
            }
        }
        wait(for: [getNextPageComplete], timeout: 1)
        guard case .loaded = list.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        let loadedListGetNextPageComplete = expectation(description: "get next page completed on loaded list")
        list.getNextPage { result in
            switch result {
            case .success:
                loadedListGetNextPageComplete.fulfill()
            case .failure(let coreError):
                XCTFail("\(coreError)")
            }
        }
        wait(for: [loadedListGetNextPageComplete], timeout: 1)
    }

    func testGetNextPageFailure() {
        let mockListProvider = MockListProvider<BasicModel>(
            errorOnNextPage: CoreError.clientValidation("", "", nil)).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let getNextPageComplete = expectation(description: "get next page completed")
        
        list.fetch { result in
            switch result {
            case .success:
                list.getNextPage { result in
                    switch result {
                    case .success:
                        XCTFail("Should have failed")
                    case .failure:
                        getNextPageComplete.fulfill()
                    }
                }
            case .failure(let coreError):
                XCTFail("\(coreError)")
            }
        }
        wait(for: [getNextPageComplete], timeout: 1)
    }

}
