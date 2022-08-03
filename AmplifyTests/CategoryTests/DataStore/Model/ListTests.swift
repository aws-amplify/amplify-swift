//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class ListTests: XCTestCase {

    override func setUp() {
        ModelListDecoderRegistry.reset()
    }

    struct BasicModel: Model {
        var id: Identifier
    }

    class MockListDecoder: ModelListDecoder {
        static func shouldDecode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> Bool {
            guard let json = try? JSONValue(from: decoder) else {
                return false
            }
            if case .array = json {
                return true
            }
            return false
        }

        static func makeListProvider<ModelType: Model>(modelType: ModelType.Type,
                                                       decoder: Decoder) throws -> AnyModelListProvider<ModelType> {
            let json = try JSONValue(from: decoder)
            if case .array = json {
                let elements = try [ModelType](from: decoder)
                return MockListProvider<ModelType>(elements: elements).eraseToAnyModelListProvider()
            } else {
                return MockListProvider<ModelType>(elements: []).eraseToAnyModelListProvider()
            }
        }
    }

    class MockListProvider<Element: Model>: ModelListProvider {
        let elements: [Element]
        var error: CoreError?
        var errorOnLoad: CoreError?
        var errorOnNextPage: CoreError?
        var nextPage: List<Element>?
        var state: ModelListProviderState<Element>?
        
        public init(elements: [Element] = [Element](),
                    error: CoreError? = nil,
                    errorOnLoad: CoreError? = nil,
                    errorOnNextPage: CoreError? = nil,
                    nextPage: List<Element>? = nil,
                    state: ModelListProviderState<Element>? = nil) {
            self.elements = elements
            self.error = error
            self.errorOnLoad = errorOnLoad
            self.errorOnNextPage = errorOnNextPage
            self.nextPage = nextPage
            self.state = state
        }

        public func getState() -> ModelListProviderState<Element> {
            state ?? .notLoaded
        }
        
        public func load(completion: (Result<[Element], CoreError>) -> Void) {
            if let error = error {
                completion(.failure(error))
            } else if let error = errorOnLoad {
                completion(.failure(error))
            } else {
                completion(.success(elements))
            }
        }

        public func hasNextPage() -> Bool {
            return nextPage != nil
        }

        public func getNextPage(completion: (Result<List<Element>, CoreError>) -> Void) {
            if let error = error {
                completion(.failure(error))
            } else if let error = errorOnNextPage {
                completion(.failure(error))
            } else if let nextPage = nextPage {
                completion(.success(nextPage))
            } else {
                fatalError("Mock not implemented")
            }
        }
    }

    func testModelListDecoderRegistry() throws {
        XCTAssertEqual(ModelListDecoderRegistry.listDecoders.get().count, 0)
        ModelListDecoderRegistry.registerDecoder(MockListDecoder.self)
        XCTAssertEqual(ModelListDecoderRegistry.listDecoders.get().count, 1)
    }

    func testDecodeWithMockListDecoder() throws {
        ModelListDecoderRegistry.registerDecoder(MockListDecoder.self)
        XCTAssertEqual(ModelListDecoderRegistry.listDecoders.get().count, 1)
        let data: JSONValue = [
            ["id": "1"],
            ["id": "2"]
        ]

        let serializedData = try ListTests.encode(json: data)
        let list = try ListTests.decode(serializedData, responseType: BasicModel.self)
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
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list.startIndex, 0)
        XCTAssertEqual(list.endIndex, 2)
        XCTAssertEqual(list.index(after: 1), 2)
        XCTAssertNotNil(list[0])
        let iterateSuccess = expectation(description: "Iterate over the list successfullly")
        iterateSuccess.expectedFulfillmentCount = 2
        list.makeIterator().forEach { _ in
            iterateSuccess.fulfill()
        }
        wait(for: [iterateSuccess], timeout: 1)
        let json = try? ListTests.toJSON(list: list)
        XCTAssertEqual(json, """
            [{\"id\":\"1\"},{\"id\":\"2\"}]
            """)
    }

    func testDecodeWithArrayLiteralListProvider() throws {
        XCTAssertEqual(ModelListDecoderRegistry.listDecoders.get().count, 0)
        let data: JSONValue = [
            ["id": "1"],
            ["id": "2"]
        ]

        let serializedData = try ListTests.encode(json: data)
        let list = try ListTests.decode(serializedData, responseType: BasicModel.self)
        XCTAssertNotNil(list)
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
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list.startIndex, 0)
        XCTAssertEqual(list.endIndex, 2)
        XCTAssertEqual(list.index(after: 1), 2)
        XCTAssertNotNil(list[0])
        let iterateSuccess = expectation(description: "Iterate over the list successfullly")
        iterateSuccess.expectedFulfillmentCount = 2
        list.makeIterator().forEach { _ in
            iterateSuccess.fulfill()
        }
        wait(for: [iterateSuccess], timeout: 1)
        XCTAssertFalse(list.listProvider.hasNextPage())
        let getNextPageFail = expectation(description: "getNextPage should fail")
        list.listProvider.getNextPage { result in
            switch result {
            case .success:
                XCTFail("Should not be successfully")
            case .failure:
                getNextPageFail.fulfill()
            }
        }
        wait(for: [getNextPageFail], timeout: 1)
    }

    func testDecodeAndEncodeEmptyArray() throws {
        XCTAssertEqual(ModelListDecoderRegistry.listDecoders.get().count, 0)
        let data: JSONValue = []
        let serializedData = try ListTests.encode(json: data)
        let list = try ListTests.decode(serializedData, responseType: BasicModel.self)
        XCTAssertNotNil(list)
        let fetchCompleted = expectation(description: "Fetch completed")
        list.fetch { result in
            XCTAssertEqual(list.count, 0)
            let json = try? ListTests.toJSON(list: list)
            XCTAssertEqual(json, "[]")
            fetchCompleted.fulfill()
        }
        wait(for: [fetchCompleted], timeout: 1)
    }

    func testLoadFailure() {
        let mockListProvider = MockListProvider<BasicModel>(
            errorOnLoad: .listOperation("", "", DataStoreError.internalOperation("", "", nil)))
            .eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let fetchCompleted = expectation(description: "Fetch completed")
        list.fetch { result in
            switch result {
            case .success:
                XCTFail("Expected to fail on load")
            case .failure:
                fetchCompleted.fulfill()
            }
        }
        wait(for: [fetchCompleted], timeout: 1)
    }

    // MARK: - Helpers

    private static func encode(json: JSONValue) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        return try encoder.encode(json)
    }

    private static func toJSON<ModelType: Model>(list: List<ModelType>) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        let data = try encoder.encode(list)
        guard let json = String(data: data, encoding: .utf8) else {
            XCTFail("Could not get JSON string from data")
            return ""
        }
        return json
    }

    private static func decode<R: Decodable>(_ data: Data, responseType: R.Type) throws -> List<R> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        return try decoder.decode(List<R>.self, from: data)
    }
}
