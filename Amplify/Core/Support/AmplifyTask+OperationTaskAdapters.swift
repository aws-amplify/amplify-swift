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

public class AmplifyOperationTaskAdapter<Request: AmplifyOperationRequest, Success, Failure: AmplifyError>: AmplifyTask {
    let operation: AmplifyOperation<Request, Success, Failure>
    let childTask: ChildTask<Void, Success, Failure>
    var resultToken: UnsubscribeToken? = nil

    public init(operation: AmplifyOperation<Request, Success, Failure>) {
        self.operation = operation
        self.childTask = ChildTask(parent: operation)
        resultToken = operation.subscribe(resultListener: resultListener)
    }

    deinit {
        if let resultToken = resultToken {
            Amplify.Hub.removeListener(resultToken)
        }
    }

    public var value: Success {
        get async throws {
            try await childTask.value
        }
    }

    public func pause() {
        operation.pause()
    }

    public func resume() {
        operation.resume()
    }

    public func cancel() {
        Task {
            await childTask.cancel()
        }
    }

#if canImport(Combine)
    public var resultPublisher: AnyPublisher<Success, Failure> {
        operation.resultPublisher
    }
#endif

    private func resultListener(_ result: Result<Success, Failure>) {
        Task {
            await childTask.finish(result)
        }
    }
}

public class AmplifyInProcessReportingOperationTaskAdapter<Request: AmplifyOperationRequest, InProcess, Success, Failure: AmplifyError>: AmplifyTask, AmplifyInProcessReportingTask {
    let operation: AmplifyInProcessReportingOperation<Request, InProcess, Success, Failure>
    let childTask: ChildTask<InProcess, Success, Failure>
    var resultToken: UnsubscribeToken? = nil
    var inProcessToken: UnsubscribeToken? = nil

    public init(operation: AmplifyInProcessReportingOperation<Request, InProcess, Success, Failure>, subscribeEnabled: Bool = true) {
        self.operation = operation
        self.childTask = ChildTask(parent: operation)
        if subscribeEnabled {
            resultToken = operation.subscribe(resultListener: resultListener)
            inProcessToken = operation.subscribe(inProcessListener: inProcessListener)
        }
    }

    deinit {
        if let resultToken = resultToken {
            Amplify.Hub.removeListener(resultToken)
        }
        if let inProcessToken = inProcessToken {
            Amplify.Hub.removeListener(inProcessToken)
        }
    }

    public var value: Success {
        get async throws {
            try await childTask.value
        }
    }

    public var inProcess: AmplifyAsyncSequence<InProcess> {
        get async {
            await childTask.inProcess
        }
    }

    public func pause() {
        operation.pause()
    }

    public func resume() {
        operation.resume()
    }

    public func cancel() {
        Task {
            await childTask.cancel()
        }
    }

#if canImport(Combine)
    public var resultPublisher: AnyPublisher<Success, Failure> {
        operation.resultPublisher
    }

    public var inProcessPublisher: AnyPublisher<InProcess, Never> {
        operation.inProcessPublisher
    }
#endif

    private func resultListener(_ result: Result<Success, Failure>) {
        Task {
            await childTask.finish(result)
        }
    }

    private func inProcessListener(_ inProcess: InProcess) {
        Task {
            try await childTask.report(inProcess)
        }
    }
}

public extension AmplifyOperationTaskAdapter where Request: RequestIdentifier {
    var requestID: String {
        operation.request.requestID
    }
}

public extension AmplifyInProcessReportingOperationTaskAdapter where Request: RequestIdentifier {
    var requestID: String {
        operation.request.requestID
    }
}
