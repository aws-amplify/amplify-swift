//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class MockAuthCategoryPlugin: MessageReporter, AuthCategoryPlugin {
    var key: String {
        return "MockAuthCategoryPlugin"
    }

    func configure(using configuration: Any) throws {
        notify()
    }

    func stub() {
        notify()
    }

    func reset() {
        notify()
    }
}

class MockSecondAuthCategoryPlugin: MockAuthCategoryPlugin {
    override var key: String {
        return "MockSecondAuthCategoryPlugin"
    }
}
