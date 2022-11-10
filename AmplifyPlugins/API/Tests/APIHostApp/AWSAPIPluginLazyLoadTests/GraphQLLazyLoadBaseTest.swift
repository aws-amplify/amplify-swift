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
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
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
        case notLoaded(identifiers: [String: String]?)
        case loaded(model: M?)
    }
    
    func assertLazyModel<M: Model>(_ lazyModel: LazyModel<M>,
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
        case isNotLoaded(associatedId: String, associatedField: String)
        case isLoaded(count: Int)
    }
    
    func assertList<M: Model>(_ list: List<M>, state: AssertListState) {
        switch state {
        case .isNotLoaded(let expectedAssociatedId, let expectedAssociatedField):
            if case .notLoaded(let associatedId, let associatedField) = list.listProvider.getState() {
                XCTAssertEqual(associatedId, expectedAssociatedId)
                XCTAssertEqual(associatedField, expectedAssociatedField)
            } else {
                XCTFail("It should be not loaded with expected associatedId \(expectedAssociatedId) associatedField \(expectedAssociatedField)")
            }
        case .isLoaded(let count):
            if case .loaded(let loadedList) = list.listProvider.getState() {
                XCTAssertEqual(loadedList.count, count)
            } else {
                XCTFail("It should be loaded with expected count \(count)")
            }
        }
    }
}
