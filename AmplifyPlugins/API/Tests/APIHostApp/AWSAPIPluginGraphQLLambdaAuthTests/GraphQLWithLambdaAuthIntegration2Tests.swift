//
//  GraphQLWithLambdaAuthIntegration2Tests.swift
//  AWSAPIPluginGraphQLLambdaAuthTests
//
//  Created by Law, Michael on 8/12/22.
//

import XCTest
@testable import Amplify
import AWSAPIPlugin
@testable import APIHostApp

final class GraphQLWithLambdaAuthIntegration2Tests: XCTestCase {

    let amplifyConfigurationFile = "testconfiguration/GraphQLWithLambdaAuthIntegrationTests-amplifyconfiguration"
    
    override func setUp() async throws{
        do {
            //try Amplify.add(plugin: AWSAPIPlugin(apiAuthProviderFactory: TestAPIAuthProviderFactory()))
            try Amplify.add(plugin: AWSAPIPlugin())
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFile)
            try Amplify.configure(amplifyConfig)

            // ModelRegistry.register(modelType: Todo.self)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
