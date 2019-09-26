//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The high-level status of an AsyncEvent
public enum AsyncEvent<InProcess, Completed, Error: AmplifyError> {
    /// The status of the AsyncEvent is unknown
    case unknown

    /// The AsyncEvent is not running. For example, it has not yet been started, or it has started and subsequently
    /// been paused
    case notInProcess

    /// The AsyncEvent is running.
    case inProcess(InProcess)

    /// The AsyncEvent is complete. No further status updates will be emitted for this event. Any result values will
    /// be available in the AsyncEvent's `value`
    case completed(Completed)

    /// The AsyncEvent failed. No further status updates will be emitted for this event. Any result values will be
    /// available in the AsyncEvent's `value`.
    case failed(Error)
}

extension AsyncEvent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .notInProcess:
            return "notInProcess"
        case .inProcess:
            return "inProcess"
        case .completed:
            return "completed"
        case .failed:
            return "failed"
        }
    }
}
