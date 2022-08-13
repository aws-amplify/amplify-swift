//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol AmplifyTask {
    associatedtype Request
    associatedtype Success
    associatedtype Failure: AmplifyError

    var result: Success { get async throws }

    func pause() async
    func resume() async
    func cancel() async
}

public protocol AmplifyInProcessReportingTask {
    associatedtype InProcess

    var inProcess: AsyncChannel<InProcess> { get async }
}

public typealias AmplifyProgressTask = AmplifyTask & AmplifyInProcessReportingTask

public extension AmplifyInProcessReportingTask where InProcess == Progress {
    var progress : AsyncChannel<InProcess> {
        get async {
            await inProcess
        }
    }
}
