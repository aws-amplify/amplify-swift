//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The high-level status of an AsyncEvent
public enum AsyncEvent<InProcessType, CompletedType, ErrorType: AmplifyError> {

    /// The status of the AsyncEvent is unknown
    case unknown

    /// The AsyncEvent is not running. For example, it has not yet been started, or it has started and subsequently
    /// been paused
    case notInProcess

    /// The AsyncEvent is running.
    case inProcess(InProcessType)

    /// The AsyncEvent is complete. No further status updates will be emitted for this event. Any result values will
    /// be available in the AsyncEvent's `value`
    case completed(CompletedType)

    /// The AsyncEvent failed. No further status updates will be emitted for this event. Any result values will be
    /// available in the AsyncEvent's `value`.
    case failed(ErrorType)
}
