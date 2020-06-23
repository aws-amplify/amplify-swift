//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class MockAuthCategoryPlugin: MessageReporter, AuthCategoryPlugin {

    var responders = Responders()

    var key: String {
        return "MockAuthCategoryPlugin"
    }

    func configure(using configuration: Any?) throws {
        notify()
    }

    func reset(onComplete: @escaping BasicClosure) {
        notify("reset")
        onComplete()
    }

}

class MockSecondAuthCategoryPlugin: MockAuthCategoryPlugin {
    override var key: String {
        return "MockSecondAuthCategoryPlugin"
    }
}
