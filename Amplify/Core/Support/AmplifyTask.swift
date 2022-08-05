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

    var progress: AsyncChannel<InProcess> { get async }
}

public typealias AmplifyProgressTask = AmplifyTask & AmplifyInProcessReportingTask
