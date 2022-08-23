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

public class FastOperationRequest: AmplifyOperationRequest {
    public let options: [AnyHashable : Any]
    public let numbers: [Int]

    public init(options: [AnyHashable : Any] = [:], numbers: [Int]) {
        self.options = options
        self.numbers = numbers
    }
}

public struct FastOperationSuccess {
    public let value: Int

    public init(value: Int) {
        self.value = value
    }
}

public enum FastOperationError: AmplifyError {
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

public typealias FastOperationResult = Result<FastOperationSuccess, FastOperationError>
public typealias FastOperationResultListener = (FastOperationResult) -> Void

public class FastOperation: AmplifyOperation<FastOperationRequest, FastOperationSuccess, FastOperationError> {
    public typealias TaskAdapter = AmplifyOperationTaskAdapter<Request, Success, Failure>
#if canImport(Combine)
    public typealias ResultPublisher = AnyPublisher<Success, Failure>
#endif

    public init(request: FastOperationRequest, resultListener: FastOperationResultListener? = nil) {
        super.init(categoryType: .storage,
                   eventName: "FastOperation",
                   request: request,
                   resultListener: resultListener)
    }

    public override func main() {
        if isCancelled {
            finish()
            return
        }

        // add the integers
        let value = request.numbers.reduce(into: 0) { result, current in
            result += current
        }

        dispatch(result: .success(FastOperationSuccess(value: value)))

        finish()
    }
}

public typealias FastTask = FastOperation.TaskAdapter
#if canImport(Combine)
public typealias FastResultPublisher = FastOperation.ResultPublisher
#endif

public extension HubPayload.EventName {
    struct Testing { }
}

public extension HubPayload.EventName.Testing {
    static let fastCompositeTask = "Testing.fastCompositeTask"
}
