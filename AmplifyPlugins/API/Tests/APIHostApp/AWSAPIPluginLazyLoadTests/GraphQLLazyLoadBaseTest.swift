//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
@testable import APIHostApp
@testable import AWSPluginsCore

class GraphQLLazyLoadBaseTest: XCTestCase {
    
    var amplifyConfig: AmplifyConfiguration!
    
    override func setUp() {
        continueAfterFailure = false
    }
    
    override func tearDown() async throws {
        await Amplify.reset()
    }
    
    func setupConfig() {
        let basePath = "testconfiguration"
        let baseFileName = "GraphQLLazyLoadTests"
        let configFile = "\(basePath)/\(baseFileName)-amplifyconfiguration"
        
        do {
            amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: configFile)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }
    
    func apiEndpointName() throws -> String {
        guard let apiPlugin = amplifyConfig.api?.plugins["awsAPIPlugin"],
              case .object(let value) = apiPlugin else {
            throw APIError.invalidConfiguration("API endpoint not found.", "Check the provided configuration")
        }
        return value.keys.first!
    }
    
    /// Setup API with given models
    /// - Parameter models: DataStore models
    func setup(withModels models: AmplifyModelRegistration,
               logLevel: LogLevel = .verbose) async {
        do {
            setupConfig()
            Amplify.Logging.logLevel = logLevel
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: models))
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
        case isNotLoaded(associatedIdentifiers: [String], associatedField: String)
        case isLoaded(count: Int)
    }
    
    func assertList<M: Model>(_ list: List<M>, state: AssertListState) {
        switch state {
        case .isNotLoaded(let expectedAssociatedIdentifiers, let expectedAssociatedField):
            if case .notLoaded(let associatedIdentifiers, let associatedField) = list.listProvider.getState() {
                XCTAssertEqual(associatedIdentifiers, expectedAssociatedIdentifiers)
                XCTAssertEqual(associatedField, expectedAssociatedField)
            } else {
                XCTFail("It should be not loaded with expected associatedId \(expectedAssociatedIdentifiers) associatedField \(expectedAssociatedField)")
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
        
        let modelType = model
        
        var primaryKeysOnly = false
        if M.rootPath != nil {
            primaryKeysOnly = true
        }
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .query,
                                                               primaryKeysOnly: primaryKeysOnly)
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
}

extension LazyReferenceIdentifier: Equatable {
    public static func == (lhs: LazyReferenceIdentifier, rhs: LazyReferenceIdentifier) -> Bool {
        return lhs.name == rhs.name && lhs.value == rhs.value
    }
}
