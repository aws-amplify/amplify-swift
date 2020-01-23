//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

final class MockReconciliationQueue: MessageReporter, IncomingEventReconciliationQueue {
    func start() {
        notify()
    }

    func pause() {
        notify()
    }

    func offer(_ remoteModel: MutationSync<AnyModel>) {
        notify("offer(_:) remoteModel: \(remoteModel)")
    }

}
