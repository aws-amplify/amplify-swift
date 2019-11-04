//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// CallType of the operation
public enum CallType {

    /// `offline` operation doesnot make network call
    case offline

    /// `auto` operation make use of online and offline calls.
    case auto
}
