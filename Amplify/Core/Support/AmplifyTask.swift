//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
#if canImport(Combine)
import Combine
#endif

public protocol AmplifyTask {
    associatedtype Request
    associatedtype Success
    associatedtype Failure: AmplifyError

    var value: Success { get async throws }

    func pause()
    func resume()
    func cancel()

#if canImport(Combine)
    var resultPublisher: AnyPublisher<Success, Failure> { get }
#endif
}

public protocol AmplifyInProcessReportingTask {
    associatedtype InProcess

    var inProcess: AmplifyAsyncSequence<InProcess> { get async }

#if canImport(Combine)
    var inProcessPublisher: AnyPublisher<InProcess, Never> { get }
#endif
}

public extension AmplifyInProcessReportingTask where InProcess == Progress {
    var progress : AmplifyAsyncSequence<InProcess> { // swiftlint:disable:this colon
        get async {
            await inProcess
        }
    }
}
