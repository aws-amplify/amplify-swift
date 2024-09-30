//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@_spi(FileBasedConfig) @testable import AWSSDKCommon

class FileBasedConfigurationTests: XCTestCase {
    let configPath = Bundle.module.path(forResource: "file_based_config_tests", ofType: nil)
    
    func testCRTFileBasedConfiguration() {
        let config: FileBasedConfiguration = try! CRTFileBasedConfiguration(
            configFilePath: configPath
        )
        let defaultSection = config.section(for: "default")
        let nestedSection = defaultSection?.subproperties(for: "nested")
        
        XCTAssertEqual(
            defaultSection?.string(for: "one-number"),
            "1"
        )
        XCTAssertEqual(
            defaultSection?.string(for: "two-word"),
            "two"
        )
        XCTAssertNil(defaultSection?.string(for: "undefined-property"))
        XCTAssertEqual(
            nestedSection?.value(for: "one-number"),
            "1"
        )
        XCTAssertEqual(
            nestedSection?.value(for: "two-word"),
            "two"
        )
        
        let namedSection = config.section(for: "test-profile")
        let nestedNameSection = namedSection?.subproperties(for: "nested")
        XCTAssertEqual(
            namedSection?.string(for: "one-word"),
            "one"
        )
        XCTAssertEqual(
            namedSection?.string(for: "two-number"),
            "2"
        )
        XCTAssertNil(namedSection?.string(for: "undefined-property"))
        XCTAssertEqual(
            nestedNameSection?.value(for: "one-word"),
            "one"
        )
        XCTAssertEqual(
            nestedNameSection?.value(for: "two-number"),
            "2"
        )
    }
    
}
