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

public protocol StorageDownloadDataOperation: AmplifyInProcessReportingOperation<
    StorageDownloadDataRequest,
    Progress,
    Data,
    StorageError
> {}

public extension HubPayload.EventName.Storage {
    /// eventName for HubPayloads emitted by this operation
    static let downloadData = "Storage.downloadData"
}

public typealias StorageDownloadDataTask = AmplifyInProcessReportingOperationTaskAdapter<StorageDownloadDataRequest,
                                                                                                  Progress,
                                                                                                  Data,
                                                                                                  StorageError>

public struct RealStorageDownloadDataTask<Request: AmplifyOperationRequest, InProcess, Success, Failure: AmplifyError>: AmplifyTask, AmplifyInProcessReportingTask {
//    public typealias Request = StorageDownloadDataRequest
//    public typealias InProcess = Progress
//    public typealias Success = Data
//    public typealias Failure = StorageError

    let operation: AmplifyInProcessReportingOperation<Request, InProcess, Success, Failure>
    let childTask: ChildTask<InProcess, Success, Failure>

    // This type can take the operation and create the TaskAdapter to use internally
    // Another initializer can take the active task context to support value and inProcess and the functions
    public init(operation: AmplifyInProcessReportingOperation<Request, InProcess, Success, Failure>) {
        self.operation = operation
        self.childTask = ChildTask(parent: operation)
    }

    public var value: Success {
        get async throws {
            Fatal.notImplemented()
        }
    }

    public var inProcess: AmplifyAsyncSequence<InProcess> {
        get async {
            Fatal.notImplemented()
        }
    }

    public func pause() {
        Fatal.notImplemented()
    }

    public func resume() {
        Fatal.notImplemented()
    }

    public func cancel() {
        Fatal.notImplemented()
    }

#if canImport(Combine)
    public var resultPublisher: AnyPublisher<Success, Failure> {
        Fatal.notImplemented()
//        Amplify.Publisher.create {
//            try await value
//        }
    }

    public var inProcessPublisher: AnyPublisher<InProcess, Never> {
//        Fatal.notImplemented()
        let sequence = AmplifyAsyncSequence<InProcess>()
//        return sequence
        let p = Amplify.Publisher.create(sequence)
        return p
    }
#endif

}
