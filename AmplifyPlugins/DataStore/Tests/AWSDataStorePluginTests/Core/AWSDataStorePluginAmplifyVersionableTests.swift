//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSDataStorePlugin
@testable import AmplifyTestCommon

// swiftlint:disable:next type_name
class AWSDataStorePluginAmplifyVersionableTests: XCTestCase {

    func testVersionExists() {
        #if os(watchOS)
        let plugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(),
                                        configuration: .subscriptionsDisabled)
        #else
        let plugin = AWSDataStorePlugin(modelRegistration: AmplifyModels())
        #endif
        XCTAssertNotNil(plugin.version)
    }

}
