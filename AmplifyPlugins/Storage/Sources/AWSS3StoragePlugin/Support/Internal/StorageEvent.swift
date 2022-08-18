//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// The high-level status of an StorageEvent
enum StorageEvent<InitiatedType, InProcessType, CompletedType, ErrorType: AmplifyError> {

    /// The StorageEvent has started.
    case initiated(InitiatedType)

    /// The StorageEvent is running.
    case inProcess(InProcessType)

    /// The StorageEvent is complete. No further status updates will be emitted for this event. Any result values will
    /// be available in the StorageEvent `value`
    case completed(CompletedType)

    /// The StorageEvent failed. No further status updates will be emitted for this event. Any result values will be
    /// available in the StorageEvent `value`.
    case failed(ErrorType)

}

extension StorageEvent where CompletedType == Void {
    static var completedVoid: StorageEvent { .completed(()) }
}
