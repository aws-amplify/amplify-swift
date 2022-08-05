//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class AmplifyOperationTaskAdapter<Request: AmplifyOperationRequest, Success, Failure: AmplifyError>: AmplifyTask {
    let operation: AmplifyOperation<Request, Success, Failure>
    let childTask: ChildTask<Void, Success, Failure>
    var resultToken: UnsubscribeToken? = nil

    init(operation: AmplifyOperation<Request, Success, Failure>) {
        self.operation = operation
        self.childTask = ChildTask(parent: operation)
        resultToken = operation.subscribe(resultListener: resultListener)
    }

    deinit {
        if let resultToken = resultToken {
            Amplify.Hub.removeListener(resultToken)
        }
    }

    var result: Success {
        get async throws {
            try await childTask.result
        }
    }

    func pause() async {
        operation.pause()
    }

    func resume() async {
        operation.resume()
    }

    func cancel() async {
        await childTask.cancel()
    }

    private func resultListener(_ result: Result<Success, Failure>) {
        Task {
            await childTask.finish(result)
        }
    }
}

class AmplifyInProcessReportingOperationTaskAdapter<Request: AmplifyOperationRequest, InProcess, Success, Failure: AmplifyError>: AmplifyTask, AmplifyInProcessReportingTask {
    let operation: AmplifyInProcessReportingOperation<Request, InProcess, Success, Failure>
    let childTask: ChildTask<InProcess, Success, Failure>
    var resultToken: UnsubscribeToken? = nil
    var inProcessToken: UnsubscribeToken? = nil

    init(operation: AmplifyInProcessReportingOperation<Request, InProcess, Success, Failure>) {
        self.operation = operation
        self.childTask = ChildTask(parent: operation)
        resultToken = operation.subscribe(resultListener: resultListener)
        inProcessToken = operation.subscribe(inProcessListener: inProcessListener)
    }

    deinit {
        if let resultToken = resultToken {
            Amplify.Hub.removeListener(resultToken)
        }
        if let inProcessToken = inProcessToken {
            Amplify.Hub.removeListener(inProcessToken)
        }
    }

    var result: Success {
        get async throws {
            try await childTask.result
        }
    }

    var progress: AsyncChannel<InProcess> {
        get async {
            await childTask.inProcess
        }
    }

    func pause() async {
        operation.pause()
    }

    func resume() async {
        operation.resume()
    }

    func cancel() async {
        await childTask.cancel()
    }

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
