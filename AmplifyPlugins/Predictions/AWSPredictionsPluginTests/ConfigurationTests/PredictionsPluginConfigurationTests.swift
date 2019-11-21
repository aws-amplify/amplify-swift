//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSPredictionsPlugin

class PredictionsPluginConfigurationTests: XCTestCase {

    /// Test basic configuration parsing works
    ///
    /// - Given: A valid json data for predictions
    /// - When:
    ///    - I decode the given data
    /// - Then:
    ///    - I should get a valid configuration object
    ///
    func testConfiguration() {
        let inputJsonData = """
        {
        "defaultRegion": "us-west-2",
        "convert": {
            "translateText": {
                "region": "us-west-2",
                "sourceLanguage": "en",
                "targetLanguage": "it"
            },
            "speechGenerator": {
                "region": "us-west-2",
                "voiceId": "Justin"
            }
        },
        "interpret": {
            "interpretText": {
                "region": "us-west-2"
            }
        },
        "identify": {
            "identifyLabels": {
                "region": "us-west-2",
                "type": "LABELS"
            },
            "identifyText": {
                "region": "us-west-2",
                "format": "ALL"
            }
        }
        }
        """.data(using: .utf8)!
        do {
            let configuration = try JSONDecoder().decode(PredictionsPluginConfiguration.self, from: inputJsonData)
            XCTAssertNotNil(configuration, "Configuration should not be nil")
            XCTAssertEqual(configuration.defaultRegion, .USWest2, "Default value should be equal to the input")
            XCTAssertEqual(configuration.identify.identifyLabels?.type, LabelType.labels, "Label type should match")
        } catch {
            XCTFail("Decoding the json data should not produce any error \(error)")
        }
    }

    /// Test decodable with only convert as subsection
    ///
    /// - Given: Json data with convert subsection
    /// - When:
    ///    - I decode the given data
    /// - Then:
    ///    - I should get a valid configuration object
    ///
    func testConfigurationWithOnlyConvert() {
        let inputJsonData = """
        {
        "defaultRegion": "us-west-2",
        "convert": {
            "translateText": {
                "region": "us-west-2",
                "sourceLanguage": "en",
                "targetLanguage": "it"
            },
            "speechGenerator": {
                "region": "us-west-2",
                "voiceId": "Justin"
            }
        }
        }
        """.data(using: .utf8)!
        do {
            let configuration = try JSONDecoder().decode(PredictionsPluginConfiguration.self, from: inputJsonData)
            XCTAssertNotNil(configuration, "Configuration should not be nil")
        } catch {
            XCTFail("Decoding the json data should not produce any error \(error)")
        }
    }

    /// Test decodable no region specified under subsection
    ///
    /// - Given: Json data with no region specified under subsection
    /// - When:
    ///    - I decode the given data
    /// - Then:
    ///    - I should get an error
    ///
    func testNoRegionUnderSubsection() {
        let inputJsonData = """
        {
        "defaultRegion": "us-west-2",
        "convert": {
            "translateText": {
                "sourceLanguage": "en",
                "targetLanguage": "it"
            }
        }
        }
        """.data(using: .utf8)!
        do {
            _ = try JSONDecoder().decode(PredictionsPluginConfiguration.self, from: inputJsonData)
            XCTFail("Should throw an error because region is not present")
        } catch {

        }
    }

    /// Test decodable with no subsections added
    ///
    /// - Given: Json data with no subsections added
    /// - When:
    ///    - I decode the given data
    /// - Then:
    ///    - I should get a valid configuration object
    ///
    func testConfigurationWithNoSubsections() {
        let inputJsonData = """
        {
        "defaultRegion": "us-west-2"
        }
        """.data(using: .utf8)!
        do {
            let configuration = try JSONDecoder().decode(PredictionsPluginConfiguration.self, from: inputJsonData)
            XCTAssertNotNil(configuration, "Configuration should not be nil")
            XCTAssertEqual(configuration.defaultRegion,
                           .USWest2,
                           "Default value should be equal to the input")
            XCTAssertEqual(configuration.identify.region,
                           .USWest2,
                           "Region value for identify should be equal to the input")
            XCTAssertEqual(configuration.interpret.region,
                           .USWest2,
                           "Region value for interpret should be equal to the input")
            XCTAssertEqual(configuration.convert.region,
                           .USWest2,
                           "Region value for convert should be equal to the input")
        } catch {
            XCTFail("Decoding the json data should not produce any error \(error)")
        }
    }

}
