//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AmplifyPlugins
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

/*
 # 16 Schema drift scenario

 type SchemaDrift @model {
   id: ID!
   enumValue: EnumDrift
 }

 enum EnumDrift {
    ONE
    TWO
    THREE
 }

 Codegenerated EnumDrift Enum has `THREE` enum case commented out to create an schema drift.
 */

@available(iOS 13.0, *)
class DataStoreSchemaDriftTests: SyncEngineIntegrationV2TestBase {

    var subscriptions: Set<AnyCancellable> = []

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: SchemaDrift.self)
        }

        let version: String = "1"
    }

    func testSchemaDrift() throws {
        setUp(withModels: TestModelRegistration())
        let startSuccess = expectation(description: "start success")
        try startAmplify {
            startSuccess.fulfill()
        }
        wait(for: [startSuccess], timeout: TestCommonConstants.networkTimeout)
        // Save some data with the missing enum case, do this by directly calling API
        // with a custom variables object. Later, decoding will fail.
        let saveSuccessWithTransformationError = expectation(description: "saved success with transformation error")
        let schemaDrift = SchemaDrift(enumValue: .one)
        let request = GraphQLRequest<SchemaDrift>.createMutation(of: schemaDrift)
        guard var input = request.variables?["input"] as? [String: String] else {
            XCTFail("Missing input object")
            return
        }
        input.updateValue("THREE", forKey: "enumValue")
        var variables = [String: Any]()
        variables.updateValue(input, forKey: "input")
        let requestWithEnumThree = GraphQLRequest(document: request.document,
                                                  variables: variables,
                                                  responseType: request.responseType,
                                                  decodePath: request.decodePath,
                                                  options: request.options)
        Amplify.API.mutate(request: requestWithEnumThree) { result in
            switch result {
            case .success(let response):
                print("\(response)")
                switch response {
                case .success(let result):
                    XCTFail("should have failed decoding \(result)")

                case .failure(let error):
                    switch error {
                    case .transformationError(let graphQLResponse, _):
                        XCTAssertTrue(graphQLResponse.contains("enumValue\":\"THREE"))
                        saveSuccessWithTransformationError.fulfill()
                    default:
                        XCTFail("Unexpected GraphQL response error \(error)")
                    }
                }
            case .failure(let error):
                XCTFail("Couldn't save with enum case `three`: \(error)")
            }
        }

        wait(for: [saveSuccessWithTransformationError], timeout: TestCommonConstants.networkTimeout)

        let dataStoreStartSuccess = expectation(description: "DataStore start success")
        Amplify.DataStore.start { result in
            if case .failure(let error) = result {
                XCTFail("\(error)")
            }
            dataStoreStartSuccess.fulfill()
        }
        wait(for: [dataStoreStartSuccess], timeout: TestCommonConstants.networkTimeout)

        // Assert that the sync engine does not retry on schema drift scenario
        guard let remoteSyncEngine = DataStoreInternal.getRemoteSyncEngine() else {
            XCTFail("Couldn't get RemoteSyncEngine, this could mean the internals have changed.")
            return
        }
        let syncEngineCleanedUp = expectation(description: "SyncEngine cleaned up")
        let syncEngineFailed = expectation(description: "SyncEngine failed")
        let syncEngineRestarting = expectation(description: "SyncEngine restarting (this should not happen)")
        syncEngineRestarting.isInverted = true
        remoteSyncEngine.publisher.sink { completion in
            switch completion {
            case .finished:
                break
            case .failure:
                syncEngineFailed.fulfill()
            }
        } receiveValue: { event in
            if case .cleanedUp = event {
                syncEngineCleanedUp.fulfill()
            }
            if case .schedulingRestart = event {
                syncEngineRestarting.fulfill()
            }
        }.store(in: &subscriptions)
        wait(for: [syncEngineCleanedUp, syncEngineFailed], timeout: TestCommonConstants.networkTimeout)
        wait(for: [syncEngineRestarting], timeout: TestCommonConstants.networkTimeout)
    }
}
