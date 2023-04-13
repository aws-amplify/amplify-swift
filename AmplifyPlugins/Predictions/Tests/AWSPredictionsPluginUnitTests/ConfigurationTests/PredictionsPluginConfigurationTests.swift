//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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
                "targetLang": "nl",
                "sourceLang": "fi",
                "region": "us-east-1",
                "defaultNetworkPolicy": "auto"
            },
            "speechGenerator": {
                "voice": "Justin",
                "language": "en-US",
                "region": "us-west-2",
                "defaultNetworkPolicy": "auto"
            },
            "transcription": {
                "region": "us-west-2",
                "language": "en-US",
                "defaultNetworkPolicy": "auto"
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
            },
            "identifyEntities": {
                "maxEntities": "50",
                "celebrityDetectionEnabled": "true",
                "region": "us-east-1",
                "collectionId": "identifyEntities7561c236-beta",
                "defaultNetworkPolicy": "auto"
            }
        }
        }
        """.data(using: .utf8)!
        do {
            let configuration = try JSONDecoder().decode(PredictionsPluginConfiguration.self, from: inputJsonData)
            XCTAssertNotNil(configuration, "Configuration should not be nil")
            XCTAssertEqual(configuration.defaultRegion, "us-west-2", "Default value should be equal to the input")
            XCTAssertEqual(configuration.identify.identifyLabels?.type, LabelType.labels, "Label type should match")

            XCTAssertEqual(configuration.convert.translateText?.sourceLanguage, LanguageType.finnish)
            XCTAssertEqual(configuration.convert.translateText?.targetLanguage, LanguageType.dutch)
            XCTAssertEqual(Int((configuration.identify.identifyEntities?.maxEntities)!), 50)
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
                "sourceLang": "en",
                "targetLang": "it"
            },
            "speechGenerator": {
                "region": "us-west-2",
                "voice": "Justin"
            },
            "transcription": {
                "region": "us-west-2",
                "language": "en-US",
                "defaultNetworkPolicy": "auto"
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
                           "us-west-2",
                           "Default value should be equal to the input")
            XCTAssertEqual(configuration.identify.region,
                           "us-west-2",
                           "Region value for identify should be equal to the input")
            XCTAssertEqual(configuration.interpret.region,
                           "us-west-2",
                           "Region value for interpret should be equal to the input")
            XCTAssertEqual(configuration.convert.region,
                           "us-west-2",
                           "Region value for convert should be equal to the input")
        } catch {
            XCTFail("Decoding the json data should not produce any error \(error)")
        }
    }

    func testThrowsOnMissingConfig() throws {
        let plugin = AWSPredictionsPlugin()
        try Amplify.add(plugin: plugin)

        let categoryConfig = PredictionsCategoryConfiguration(plugins: ["NonExistentPlugin": true])
        let amplifyConfig = AmplifyConfiguration(predictions: categoryConfig)
        do {
            try Amplify.configure(amplifyConfig)
            XCTFail("Should have thrown a pluginConfigurationError if not supplied with a plugin-specific config.")
        } catch {
            guard case PluginError.pluginConfigurationError = error else {
                XCTFail("Should have thrown a pluginConfigurationError if not supplied with a plugin-specific config.")
                return
            }
        }
    }

    func testConfigureFailureForNilConfiguration() throws {
        let plugin = AWSPredictionsPlugin()
        do {
            try plugin.configure(using: nil)
            XCTFail("Predictions configuration should not succeed")
        } catch {
            guard let pluginError = error as? PluginError,
                case .pluginConfigurationError = pluginError else {
                    XCTFail("Should throw invalidConfiguration exception. But received \(error) ")
                    return
            }
        }
    }
}
