//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class MockHubCategoryPlugin: MessageReporter, HubCategoryPlugin {
    var key: String {
        return "MockHubCategoryPlugin"
    }

    func configure(using configuration: Any) throws {
        notify()
    }

    func reset() {
        notify()
    }

    func dispatch(to channel: HubChannel, payload: HubPayload) {
        notify()
    }
}

class MockSecondHubCategoryPlugin: MockHubCategoryPlugin {
    override var key: String {
        return "MockSecondHubCategoryPlugin"
    }
}
