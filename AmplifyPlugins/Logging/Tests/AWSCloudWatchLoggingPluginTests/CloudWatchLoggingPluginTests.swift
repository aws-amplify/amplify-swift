////
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCloudWatchLoggingPlugin

import XCTest

final class CloudWatchLoggingPluginTests: XCTestCase {
    
    var systemUnderTest: AWSCloudWatchLoggingPlugin!
    var logGroupName: String!
    var region: String!

    override func setUpWithError() throws {
        self.logGroupName = UUID().uuidString
        self.region = UUID().uuidString
        self.systemUnderTest = AWSCloudWatchLoggingPlugin()
    }
    
    override func tearDownWithError() throws {
        self.logGroupName = nil
        self.region = nil
        self.systemUnderTest = nil
    }
}
