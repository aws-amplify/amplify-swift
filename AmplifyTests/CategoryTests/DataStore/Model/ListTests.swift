//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

// swiftlint:disable:next type_body_length
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
        var nextPage: List<Element>?

        public init(elements: [Element] = [Element](),
                    error: CoreError? = nil,
                    nextPage: List<Element>? = nil) {
            self.elements = elements
            self.error = error
            self.nextPage = nextPage
        }

        public func load() -> Result<[Element], CoreError> {
            if let error = error {
                return .failure(error)
            } else {
                return .success(elements)
            }
        }

        public func load(completion: (Result<[Element], CoreError>) -> Void) {
            if let error = error {
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
        XCTAssertEqual(list.count, 0)
        let json = try? ListTests.toJSON(list: list)
        XCTAssertEqual(json, "[]")
    }

    func testLoadWithCompletion() throws {
        XCTAssertEqual(ModelListDecoderRegistry.listDecoders.get().count, 0)
        let data: JSONValue = [
            ["id": "1"],
            ["id": "2"]
        ]

        let serializedData = try ListTests.encode(json: data)
        let list = try ListTests.decode(serializedData, responseType: BasicModel.self)
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let loadComplete = expectation(description: "Load completed")
        list.load { result in
            switch result {
            case .success(let elements):
                XCTAssertEqual(elements.count, 2)
                loadComplete.fulfill()
            case .failure(let dataStoreError):
                XCTFail("\(dataStoreError)")
            }
        }
        wait(for: [loadComplete], timeout: 1)
        guard case .loaded = list.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        let loadedStateLoadComplete = expectation(description: "Load when in Loaded state completed")
        list.load { result in
            switch result {
            case .success(let elements):
                XCTAssertEqual(elements.count, 2)
                loadedStateLoadComplete.fulfill()
            case .failure(let dataStoreError):
                XCTFail("\(dataStoreError)")
            }
        }
        wait(for: [loadedStateLoadComplete], timeout: 1)
    }

    func testLoadWithCompletionWhenUnderlyingDataStoreError_InternalOperationFailure() {
        let mockListProvider = MockListProvider<BasicModel>(
            elements: [BasicModel](),
            error: .listOperation("", "", DataStoreError.internalOperation("", "", nil))).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        let loadComplete = expectation(description: "Load completed")
        list.load { result in
            switch result {
            case .failure(let error):
                guard case .internalOperation = error else {
                    XCTFail("error should be DataStore Error")
                    return
                }
                loadComplete.fulfill()
            case .success:
                XCTFail("Should have failed")
            }
        }
        wait(for: [loadComplete], timeout: 1)
    }

    func testListLoadWithCompletionWhenListOperationError_InvalidOperationFailure() {
        let mockListProvider = MockListProvider<BasicModel>(
            elements: [BasicModel](),
            error: .listOperation("", "", nil)).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        let loadComplete = expectation(description: "Load completed")
        list.load { result in
            switch result {
            case .failure(let error):
                guard case .invalidOperation = error else {
                    XCTFail("error should be DataStoreError.invalidOperation")
                    return
                }
                loadComplete.fulfill()
            case .success:
                XCTFail("Should have failed")
            }
        }
        wait(for: [loadComplete], timeout: 1)
    }

    func testListLoadWithCompletionWhenClientValidationError_InvalidOperationFailure() {
        let mockListProvider = MockListProvider<BasicModel>(
            elements: [BasicModel](),
            error: .clientValidation("", "", nil)).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        let loadComplete = expectation(description: "Load completed")
        list.load { result in
            switch result {
            case .failure(let error):
                guard case .invalidOperation = error else {
                    XCTFail("error should be DataStoreError.invalidOperation")
                    return
                }
                loadComplete.fulfill()
            case .success:
                XCTFail("Should have failed")
            }
        }
        wait(for: [loadComplete], timeout: 1)
    }

    func testListLoadWithCompletionWhenUnknownError_InvalidOperationFailure() {
        let mockListProvider = MockListProvider<BasicModel>(
            elements: [BasicModel](),
            error: .listOperation("", "", nil)).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        let loadComplete = expectation(description: "Load completed")
        list.load { result in
            switch result {
            case .failure(let error):
                guard case .invalidOperation = error else {
                    XCTFail("error should be DataStoreError.invalidOperation")
                    return
                }
                loadComplete.fulfill()
            case .success:
                XCTFail("Should have failed")
            }
        }
        wait(for: [loadComplete], timeout: 1)
    }

    func testImplicitLoadFailure() {
        let mockListProvider = MockListProvider<BasicModel>(
            elements: [BasicModel](),
            error: .listOperation("", "", DataStoreError.internalOperation("", "", nil)))
            .eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        XCTAssertEqual(list.count, 0)
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
    }

    func testSynchronousLoadSuccess() throws {
        XCTAssertEqual(ModelListDecoderRegistry.listDecoders.get().count, 0)
        let data: JSONValue = [
            ["id": "1"],
            ["id": "2"]
        ]

        let serializedData = try ListTests.encode(json: data)
        let list = try ListTests.decode(serializedData, responseType: BasicModel.self)
        guard case .notLoaded = list.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        list.load()
        XCTAssertEqual(list.count, 2)
        guard case .loaded = list.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        list.load()
        XCTAssertEqual(list.count, 2)
    }

    func testSynchronousLoadFailWithAssert() throws {
        let mockListProvider = MockListProvider<BasicModel>(
            elements: [BasicModel](),
            error: .listOperation("", "", nil)).eraseToAnyModelListProvider()
        let list = List(listProvider: mockListProvider)
        try XCTAssertThrowFatalError {
            list.load()
        }
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
