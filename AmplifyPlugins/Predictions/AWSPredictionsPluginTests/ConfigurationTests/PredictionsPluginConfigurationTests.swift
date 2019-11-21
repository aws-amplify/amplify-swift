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
        let decoder = JSONDecoder()
        do {
            let configuration = try decoder.decode(PredictionsPluginConfiguration.self, from: inputJsonData)
            XCTAssertNotNil(configuration, "Configuration should not be nil")
            XCTAssertEqual(configuration.defaultRegion, .USWest2, "")
        } catch {
            XCTFail("Decoding the json data should not produce any error \(error)")
        }
    }

    func testConfigurationWithConvert() {
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
        let decoder = JSONDecoder()
        do {
            let configuration = try decoder.decode(PredictionsPluginConfiguration.self, from: inputJsonData)
            XCTAssertNotNil(configuration, "Configuration should not be nil")
        } catch {
            XCTFail("Decoding the json data should not produce any error \(error)")
        }
    }

    func testConfigurationWithNoRegion() {
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
        let decoder = JSONDecoder()
        do {
            _ = try decoder.decode(PredictionsPluginConfiguration.self, from: inputJsonData)
            XCTFail("Should through an error because region is not present")
        } catch {

        }
    }

}
