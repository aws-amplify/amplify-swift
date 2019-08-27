//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The high-level status of an CompletionEvent
public enum CompletionEvent<CompletedType, ErrorType: AmplifyError> {

    /// The CompletionEvent is complete. Any result values will be available in the CompletionEvent's `value`
    case completed(CompletedType)

    /// The CompletionEvent failed. Any result values will be available in the CompletionEvent's `value`.
    case failed(ErrorType)
}
