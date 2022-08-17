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
import Amplify

public class LongOperationRequest: AmplifyOperationRequest, RequestIdentifier {
    public let options: [AnyHashable : Any]
    public let steps: Int
    public let delay: Double
    public let requestID: String

    public init(options: [AnyHashable : Any] = [:], steps: Int, delay: Double) {
        self.options = options
        self.steps = steps
        self.delay = delay
        self.requestID = UUID().uuidString
    }
}

public struct LongOperationSuccess {
    let id = UUID().uuidString
}

public enum LongOperationError: AmplifyError {
    case unknown(ErrorDescription, Error? = nil)

    public var errorDescription: ErrorDescription {
        switch self {
        case .unknown(let errorDescription, _):
            return "Unexpected error occurred with message: \(errorDescription)"
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .unknown:
            return "No suggestion"
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .unknown(_, let error):
            return error
        }
    }

    public init(
        errorDescription: ErrorDescription = "An unknown error occurred",
        recoverySuggestion: RecoverySuggestion = "(Ignored)",
        error: Error
    ) {
        if let error = error as? Self {
            self = error
        } else {
            self = .unknown(errorDescription, error)
        }
    }
}

public typealias LongOperationResult = Result<LongOperationSuccess, LongOperationError>
public typealias LongOperationProgressListener = (AmplifyProgress) -> Void
public typealias LongOperationResultListener = (LongOperationResult) -> Void

public class LongOperation: AmplifyInProcessReportingOperation<LongOperationRequest, AmplifyProgress, LongOperationSuccess, LongOperationError> {
    public typealias TaskAdapter = AmplifyInProcessReportingOperationTaskAdapter<Request, InProcess, Success, Failure>
#if canImport(Combine)
    public typealias ResultPublisher = AnyPublisher<Success, Failure>
    public typealias ProgressPublisher = AnyPublisher<InProcess, Failure>
#endif

    var count = 0
    var currentProgress: Progress!

    public init(request: LongOperationRequest,
                progressListener: LongOperationProgressListener? = nil,
                resultListener: LongOperationResultListener? = nil) {
        super.init(categoryType: .storage, eventName: "LongOperation",
                   request: request,
                   inProcessListener: progressListener,
                   resultListener: resultListener)
    }

    public override func main() {
        if isCancelled {
            finish()
            return
        }

        currentProgress = Progress(totalUnitCount: Int64(request.steps))

        work()
    }

    private func work() {
        if isCancelled {
            finish()
            return
        }

        reportProgress()

        if count < request.steps {
            DispatchQueue.global().asyncAfter(deadline: .now() + request.delay, execute: advance)
        } else {
            dispatch(result: .success(LongOperationSuccess()))
            finish()
        }
    }

    private func advance() {
        count += 1
        work()
    }

    private func reportProgress() {
        currentProgress.completedUnitCount = Int64(count)
        dispatchInProcess(data: AmplifyProgress(progress: currentProgress))
    }
}

public typealias LongTask = LongOperation.TaskAdapter
#if canImport(Combine)
public typealias LongResultPublisher = LongOperation.ResultPublisher
public typealias LongProgressPublisher = LongOperation.ProgressPublisher
#endif
