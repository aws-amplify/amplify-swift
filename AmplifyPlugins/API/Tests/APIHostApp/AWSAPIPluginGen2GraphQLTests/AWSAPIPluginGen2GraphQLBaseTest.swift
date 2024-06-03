//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@_spi(InternalAmplifyConfiguration) @testable import Amplify
@testable import APIHostApp
@testable import AWSPluginsCore
import AWSCognitoAuthPlugin

class AWSAPIPluginGen2GraphQLBaseTest: XCTestCase {

    var defaultTestEmail = "test-\(UUID().uuidString)@amazon.com"
    
    var amplifyConfig: AmplifyOutputsData!

    override func setUp() {
        continueAfterFailure = false
    }

    override func tearDown() async throws {
        await Amplify.reset()
        try await Task.sleep(seconds: 1)
    }

    func setupConfig() {
        let basePath = "testconfiguration"
        let baseFileName = "Gen2GraphQLTests"
        let configFile = "\(basePath)/\(baseFileName)-amplify_outputs"

        do {
            amplifyConfig = try TestConfigHelper.retrieveAmplifyOutputsData(forResource: configFile)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    /// Setup API with given models
    /// - Parameter models: DataStore models
    func setup(withModels models: AmplifyModelRegistration,
               logLevel: LogLevel = .verbose,
               withAuthPlugin: Bool = false) async {
        do {
            setupConfig()
            Amplify.Logging.logLevel = logLevel
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: models))
            if withAuthPlugin {
                try Amplify.add(plugin: AWSCognitoAuthPlugin())
            }
            try Amplify.configure(amplifyConfig)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    @discardableResult
    func mutate<M: Model>(_ request: GraphQLRequest<M>) async throws -> M {
        do {
            let graphQLResponse = try await Amplify.API.mutate(request: request)
            switch graphQLResponse {
            case .success(let model):
                return model
            case .failure(let graphQLError):
                XCTFail("Failed with error \(graphQLError)")
            }
        } catch {
            XCTFail("Failed with error \(error)")
        }

        throw "See XCTFail message"
    }

    func query<M: Model>(_ request: GraphQLRequest<M?>) async throws -> M? {
        do {
            let graphQLResponse = try await Amplify.API.query(request: request)
            switch graphQLResponse {
            case .success(let model):
                return model
            case .failure(let graphQLError):
                XCTFail("Failed with error \(graphQLError)")
            }
        } catch {
            XCTFail("Failed with error \(error)")
        }
        throw "See XCTFail message"
    }

    func listQuery<M: Model>(_ request: GraphQLRequest<List<M>>) async throws -> List<M> {
        do {
            let graphQLResponse = try await Amplify.API.query(request: request)
            switch graphQLResponse {
            case .success(let models):
                return models
            case .failure(let graphQLError):
                XCTFail("Failed with error \(graphQLError)")
            }
        } catch {
            XCTFail("Failed with error \(error)")
        }
        throw "See XCTFail message"
    }

    enum AssertLazyModelState<M: Model> {
        case notLoaded(identifiers: [LazyReferenceIdentifier]?)
        case loaded(model: M?)
    }

    func assertLazyReference<M: Model>(_ lazyModel: LazyReference<M>,
                                   state: AssertLazyModelState<M>) {
        switch state {
        case .notLoaded(let expectedIdentifiers):
            if case .notLoaded(let identifiers) = lazyModel.modelProvider.getState() {
                XCTAssertEqual(identifiers, expectedIdentifiers)
            } else {
                XCTFail("Should be not loaded with identifiers \(expectedIdentifiers)")
            }
        case .loaded(let expectedModel):
            if case .loaded(let model) = lazyModel.modelProvider.getState() {
                guard let expectedModel = expectedModel, let model = model else {
                    XCTAssertNil(model)
                    return
                }
                XCTAssertEqual(model.identifier, expectedModel.identifier)
            } else {
                XCTFail("Should be loaded with model \(String(describing: expectedModel))")
            }
        }
    }

    enum AssertListState {
        case isNotLoaded(associatedIdentifiers: [String], associatedFields: [String])
        case isLoaded(count: Int)
    }

    func assertList<M: Model>(_ list: List<M>, state: AssertListState) {
        switch state {
        case .isNotLoaded(let expectedAssociatedIdentifiers, let expectedAssociatedFields):
            if case .notLoaded(let associatedIdentifiers, let associatedFields) = list.listProvider.getState() {
                XCTAssertEqual(associatedIdentifiers, expectedAssociatedIdentifiers)
                XCTAssertEqual(associatedFields, expectedAssociatedFields)
            } else {
                XCTFail("It should be not loaded with expected associatedIds \(expectedAssociatedIdentifiers) associatedFields \(expectedAssociatedFields)")
            }
        case .isLoaded(let count):
            if case .loaded(let loadedList) = list.listProvider.getState() {
                XCTAssertEqual(loadedList.count, count)
            } else {
                XCTFail("It should be loaded with expected count \(count)")
            }
        }
    }

    func assertModelExists<M: Model>(_ model: M) async throws {
        let modelExists = try await query(for: model) != nil
        XCTAssertTrue(modelExists)
    }

    func assertModelDoesNotExist<M: Model>(_ model: M) async throws {
        let modelExists = try await query(for: model) != nil
        XCTAssertFalse(modelExists)
    }

    func query<M: Model>(for model: M, includes: IncludedAssociations<M> = { _ in [] }) async throws -> M? {
        let id = M.identifier(model)(schema: model.schema)

        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: model.schema,
                                                               operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))

        if let modelPath = M.rootPath as? ModelPath<M> {
            let associations = includes(modelPath)
            documentBuilder.add(decorator: IncludeAssociationDecorator(associations))
        }
        documentBuilder.add(decorator: ModelIdDecorator(identifierFields: id.fields))
        let document = documentBuilder.build()

        let request = GraphQLRequest<M?>(document: document.stringValue,
                                         variables: document.variables,
                                         responseType: M?.self,
                                         decodePath: document.name)
        return try await query(request)
    }

    func subscribe<M: Model>(
        of modelType: M.Type,
        type: GraphQLSubscriptionType,
        verifyChange: @escaping (M) async throws -> Bool
    ) async throws -> (XCTestExpectation, AmplifyAsyncThrowingSequence<GraphQLSubscriptionEvent<M>>) {
        let connected = expectation(description: "Subscription connected")
        let eventReceived = expectation(description: "\(type.rawValue) received")
        let subscription = Amplify.API.subscribe(request: .subscription(of: modelType, type: type))

        Task {
            for try await subscriptionEvent in subscription {
                if subscriptionEvent.isConnected() {
                    connected.fulfill()
                }

                if let error = subscriptionEvent.extractError() {
                    XCTFail("Failed to \(type.rawValue) \(modelType), error: \(error.errorDescription)")
                }

                if let data = subscriptionEvent.extractData(),
                   try await verifyChange(data)
                {
                    eventReceived.fulfill()
                }
            }
        }

        await fulfillment(of: [connected], timeout: 10)
        return (eventReceived, subscription)
    }
}

extension LazyReferenceIdentifier: Equatable {
    public static func == (lhs: LazyReferenceIdentifier, rhs: LazyReferenceIdentifier) -> Bool {
        return lhs.name == rhs.name && lhs.value == rhs.value
    }
}


extension GraphQLSubscriptionEvent {
    func isConnected() -> Bool {
        if case .connection(.connected) = self {
            return true
        }
        return false
    }

    func extractData() -> T? {
        if case .data(.success(let data)) = self {
            return data
        }
        return nil
    }

    func extractError() -> GraphQLResponseError<T>? {
        if case .data(.failure(let error)) = self {
            return error
        }
        return nil
    }

}
